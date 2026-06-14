use std::{
    io::{self, Stdout},
    path::Path,
    sync::mpsc::{self, Receiver, TryRecvError},
    thread::{self, JoinHandle},
};

use anyhow::Result;
use arboard::Clipboard;
use crossterm::{
    event::{KeyCode, KeyEventKind, KeyModifiers},
    execute,
    terminal::{EnterAlternateScreen, LeaveAlternateScreen, disable_raw_mode, enable_raw_mode},
};
use petgraph::graph::NodeIndex;
use ratatui::{
    Terminal,
    backend::CrosstermBackend,
    layout::{Constraint, Direction, Layout, Rect},
    prelude::Frame,
    style::{Color, Modifier, Style},
    symbols::{border, line},
    text::{Line, Span},
    widgets::{Block, Borders, Gauge, List, ListItem, ListState},
};
use tui_treelistview::{
    SimpleColumns, TreeAction, TreeEvent, TreeListView, TreeListViewState, TreeListViewStyle,
};

use crate::{
    cache::{Cache, LoadProgress},
    nix,
    store_graph::StoreGraph,
    ui::{
        GcRootModel, format_size, is_direnv_path,
        key_handler::{Command, Fold, KeyHandler, Motion, Recurse},
        tree::{Label, PendingAction, make_columns},
    },
};

enum LoadMessage {
    Progress(LoadProgress),
    Done(GcRootModel),
    Error(anyhow::Error),
}

#[derive(Clone, Copy, PartialEq, Default)]
pub enum PrimaryFocus {
    #[default]
    Progress,
    Tree,
    Ranger,
}

#[derive(Clone, Copy, PartialEq, Default)]
pub enum SecondaryFocus {
    #[default]
    None,
    #[expect(dead_code)] // TODO
    Search,
}

pub struct App {
    pub quit: bool,
    pub needs_redraw: bool,
    pub primary_focus: PrimaryFocus,
    #[expect(dead_code)] // TODO:
    pub secondary_focus: SecondaryFocus,
    pub clipboard: Result<Clipboard>,

    pub model: Option<GcRootModel>,
    pub view: Option<ViewState>,
    pub progress: Option<LoadProgress>,
    loader: Option<(JoinHandle<()>, Receiver<LoadMessage>)>,
}

pub struct ViewState {
    pub tree: TreeListViewState<NodeIndex>,
    pub label: Label,
    pub columns: SimpleColumns<1, GcRootModel>,
    pub pending_action: PendingAction,
    pub key_handler: KeyHandler,
    pub visible_rows: u16,
}

impl Default for App {
    fn default() -> Self {
        Self {
            quit: false,
            needs_redraw: true,
            primary_focus: PrimaryFocus::Progress,
            secondary_focus: SecondaryFocus::None,
            clipboard: Clipboard::new().map_err(Into::into),
            model: None,
            view: None,
            progress: Some(LoadProgress::GcRoots),
            loader: None,
        }
    }
}

impl App {
    pub fn run(&mut self) -> Result<()> {
        enable_raw_mode()?;
        let mut stdout = io::stdout();
        execute!(stdout, EnterAlternateScreen)?;
        let backend = CrosstermBackend::new(stdout);
        let mut terminal = Terminal::new(backend)?;

        self.start_loading();

        while !self.quit {
            self.poll_loader();

            if self.needs_redraw {
                self.render(&mut terminal)?;
                self.needs_redraw = false;
            }

            if crossterm::event::poll(std::time::Duration::from_millis(50))?
                && let crossterm::event::Event::Key(key) = crossterm::event::read()?
                && key.kind == KeyEventKind::Press
            {
                self.handle_key(key.modifiers, key.code);
            }
        }

        disable_raw_mode()?;
        execute!(terminal.backend_mut(), LeaveAlternateScreen)?;
        Ok(())
    }

    fn start_loading(&mut self) {
        let (tx, rx) = mpsc::sync_channel(100);
        let handle = thread::spawn(move || {
            let result = (|| {
                tx.send(LoadMessage::Progress(LoadProgress::GcRoots)).ok();
                let roots = nix::gc_roots()?;

                let cache = Cache::open(Path::new("/home/nregner/.cache/nix-gc-roots"))?;
                let txn = cache.txn()?;
                let roots = txn.resolve(roots, |progress| {
                    tx.send(LoadMessage::Progress(progress)).ok();
                })?;

                tx.send(LoadMessage::Progress(LoadProgress::BuildGraph))
                    .ok();
                let dominators = StoreGraph::build(&roots);
                let model = GcRootModel::new(dominators);

                anyhow::Ok(model)
            })();

            match result {
                Ok(model) => {
                    tx.send(LoadMessage::Done(model)).ok();
                }
                Err(e) => {
                    tx.send(LoadMessage::Error(e)).ok();
                }
            }
        });
        self.loader = Some((handle, rx));
    }

    fn poll_loader(&mut self) {
        let Some((_, rx)) = &self.loader else { return };

        loop {
            match rx.try_recv() {
                Ok(LoadMessage::Progress(progress)) => {
                    self.progress = Some(progress);
                    self.needs_redraw = true;
                }
                Ok(LoadMessage::Done(model)) => {
                    self.model = Some(model);
                    self.progress = None;
                    self.loader = None;
                    self.init_view();
                    self.needs_redraw = true;
                    return;
                }
                Ok(LoadMessage::Error(e)) => {
                    self.progress = Some(LoadProgress::Error(format!("{e}")));
                    self.loader = None;
                    self.needs_redraw = true;
                    return;
                }
                Err(TryRecvError::Empty) => return,
                Err(TryRecvError::Disconnected) => {
                    self.loader = None;
                    return;
                }
            }
        }
    }

    fn render(&mut self, terminal: &mut Terminal<CrosstermBackend<Stdout>>) -> Result<()> {
        terminal.draw(|f| {
            let area = f.area();
            match self.primary_focus {
                PrimaryFocus::Progress => {
                    if let Some(ref progress) = self.progress {
                        let center = centered_rect(area, 60, 3);
                        render_progress(f, progress, center);
                    }
                }
                PrimaryFocus::Tree => {
                    if let (Some(model), Some(view)) = (&self.model, &mut self.view) {
                        render_tree(f, model, view, area);
                    }
                }
                PrimaryFocus::Ranger => {
                    if let (Some(model), Some(view)) = (&self.model, &mut self.view) {
                        render_ranger(f, model, view, area);
                    }
                }
            }
        })?;
        Ok(())
    }

    fn handle_key(&mut self, modifiers: KeyModifiers, code: KeyCode) {
        self.needs_redraw = true;

        if modifiers == KeyModifiers::CONTROL && code == KeyCode::Char('c') {
            self.quit = true;
            return;
        }

        match self.primary_focus {
            PrimaryFocus::Progress => self.handle_progress_key(modifiers, code),
            PrimaryFocus::Tree => self.handle_tree_key(modifiers, code),
            PrimaryFocus::Ranger => self.handle_ranger_key(modifiers, code),
        }
    }

    fn handle_progress_key(&mut self, modifiers: KeyModifiers, code: KeyCode) {
        if let (KeyModifiers::NONE, KeyCode::Char('q') | KeyCode::Esc) = (modifiers, code) {
            self.quit = true;
        }
    }

    // TODO: dedupe
    fn handle_tree_key(&mut self, modifiers: KeyModifiers, code: KeyCode) {
        let (Some(model), Some(view)) = (&mut self.model, &mut self.view) else {
            return;
        };

        if view.pending_action != PendingAction::None {
            match (modifiers, code) {
                (_, KeyCode::Char('y' | 'Y')) => {
                    let action = view.pending_action;
                    view.pending_action = PendingAction::None;
                    match action {
                        PendingAction::Delete => {
                            // TODO: implement delete
                        }
                        PendingAction::Reset => {
                            model.reset_marks();
                        }
                        PendingAction::None => {}
                    }
                }
                _ => {
                    view.pending_action = PendingAction::None;
                }
            }
            return;
        }

        match view.key_handler.process(modifiers, code) {
            Command::Motion(motion) => {
                let (action, count): (TreeAction<()>, u16) = match motion {
                    Motion::Up(count) => {
                        (TreeAction::SelectPrev, count.try_into().unwrap_or(u16::MAX))
                    }
                    Motion::Down(count) => {
                        (TreeAction::SelectNext, count.try_into().unwrap_or(u16::MAX))
                    }
                    Motion::Left => {
                        handle_tree_fold(view, model, Fold::Close, Recurse::No);
                        (TreeAction::SelectParent, 1)
                    }
                    Motion::Right => {
                        handle_tree_fold(view, model, Fold::Open, Recurse::No);
                        (TreeAction::SelectChild, 1)
                    }
                    Motion::HalfPageUp => (TreeAction::SelectPrev, view.visible_rows.div_ceil(2)),
                    Motion::HalfPageDown => (TreeAction::SelectNext, view.visible_rows.div_ceil(2)),
                    Motion::First => (TreeAction::SelectFirst, 1),
                    Motion::Last => (TreeAction::SelectLast, 1),
                };
                for _ in 0..count {
                    view.tree.handle_action(model, action);
                }
                return;
            }
            Command::Fold(fold, recurse, mut count) => {
                while count > 0 && handle_tree_fold(view, model, fold, recurse) {
                    count -= 1;
                }
                return;
            }
            Command::Pending => return,
            Command::Unhandled => {}
        }

        match (modifiers, code) {
            (KeyModifiers::NONE, KeyCode::Esc) => {
                self.quit = true;
            }
            (KeyModifiers::NONE, KeyCode::Enter) => {
                if let Some(id) = view.tree.selected_id() {
                    view.tree.set_expanded(id, model.root_id, true);
                }
            }
            (KeyModifiers::NONE, KeyCode::Char('y')) => {
                if let Some(id) = view.tree.selected_id()
                    && let Some(path) = model.path(id)
                {
                    // TODO: handle error
                    if let Ok(clipboard) = self.clipboard.as_mut() {
                        let _ = clipboard.set_text(path.as_os_str().to_string_lossy());
                    }
                    // TODO: show status line message
                }
            }
            (KeyModifiers::NONE, KeyCode::Char('D')) if model.marked_count() > 0 => {
                view.pending_action = PendingAction::Delete;
            }
            (KeyModifiers::NONE, KeyCode::Tab) => {
                self.primary_focus = PrimaryFocus::Ranger;
            }
            (KeyModifiers::NONE, KeyCode::Char('d')) => {
                if let Some(id) = view.tree.selected_id() {
                    model.toggle_mark(id);
                }
            }
            (KeyModifiers::NONE, KeyCode::Char('r')) if model.marked_count() > 0 => {
                view.pending_action = PendingAction::Reset;
            }
            (KeyModifiers::NONE, KeyCode::Char('p')) => {
                model.toggle_profiles();
                view.tree.invalidate_all();
            }
            _ => {}
        }
    }

    fn handle_ranger_key(&mut self, modifiers: KeyModifiers, code: KeyCode) {
        let (Some(model), Some(view)) = (&mut self.model, &mut self.view) else {
            return;
        };

        match view.key_handler.process(modifiers, code) {
            Command::Motion(motion) => {
                match motion {
                    Motion::Up(count) => {
                        ranger_select_sibling(view, model, -(count as isize));
                    }
                    Motion::Down(count) => {
                        ranger_select_sibling(view, model, count as isize);
                    }
                    Motion::Left => ranger_move_left(view, model),
                    Motion::Right => {
                        ranger_select_child(view, model);
                    }
                    Motion::First => {
                        ranger_select_sibling(view, model, isize::MIN);
                    }
                    Motion::Last => {
                        ranger_select_sibling(view, model, isize::MAX);
                    }
                    Motion::HalfPageUp => {
                        let count = view.visible_rows.div_ceil(2) as usize;
                        ranger_select_sibling(view, model, -(count as isize));
                    }
                    Motion::HalfPageDown => {
                        let count = view.visible_rows.div_ceil(2) as usize;
                        ranger_select_sibling(view, model, count as isize);
                    }
                }
                return;
            }
            Command::Fold(..) | Command::Pending => return,
            Command::Unhandled => {}
        }

        match (modifiers, code) {
            (_, KeyCode::Char('q')) | (_, KeyCode::Esc) => {
                self.quit = true;
            }
            (_, KeyCode::Char('d')) => {
                if let Some(id) = view.tree.selected_id() {
                    model.toggle_mark(id);
                }
            }
            (_, KeyCode::Char('r')) => {
                model.reset_marks();
            }
            (_, KeyCode::Tab) => {
                self.primary_focus = PrimaryFocus::Tree;
            }
            _ => {}
        }
    }

    fn init_view(&mut self) {
        let Some(ref model) = self.model else { return };

        let mut tree = TreeListViewState::with_capacity(model.graph.node_count());

        for ni in model.graph.node_indices() {
            if let Some(path) = model.path(ni) {
                let children = model.children(ni);
                if !children.is_empty() && !is_direnv_path(path) {
                    tree.set_expanded(ni, model.root_id, true);
                }
            }
        }

        if let Some(root_id) = model.root_id {
            let children = model.children(root_id);
            if !children.is_empty() {
                tree.select_by_id(model, children[0]);
            }
        }

        self.view = Some(ViewState {
            tree,
            label: Label::new(),
            columns: make_columns(),
            pending_action: PendingAction::None,
            key_handler: KeyHandler::default(),
            visible_rows: 20,
        });
        self.primary_focus = PrimaryFocus::Ranger;
    }
}

#[derive(Clone, Copy)]
enum FoldAction {
    Open,
    Close,
}

fn handle_tree_fold(
    view: &mut ViewState,
    model: &GcRootModel,
    fold: Fold,
    recurse: Recurse,
) -> bool {
    use Fold::*;
    use Recurse::*;
    let action = match (fold, recurse) {
        (Open, No) => TreeAction::Custom(FoldAction::Open),
        (Open, Yes) => TreeAction::ExpandAll,
        (Close, No) => TreeAction::Custom(FoldAction::Close),
        (Close, Yes) => TreeAction::CollapseAll,
        (Alternate, No) => TreeAction::ToggleNode,
        (Alternate, Yes) => TreeAction::ToggleRecursive,
        (Reduce, _) => TreeAction::ExpandAll,
        (More, _) => TreeAction::CollapseAll,
    };

    if let TreeEvent::Action(TreeAction::Custom(fold_action)) =
        view.tree.handle_action(model, action)
        && let Some(id) = view.tree.selected_id()
    {
        let expand = matches!(fold_action, FoldAction::Open);
        view.tree
            .set_expanded(id, view.tree.selected_parent_id(), expand);
        return true;
    }

    false
}

fn centered_rect(area: Rect, percent_x: u16, height: u16) -> Rect {
    let [_, center, _] = Layout::default()
        .direction(Direction::Vertical)
        .constraints([
            Constraint::Percentage(40),
            Constraint::Length(height),
            Constraint::Percentage(40),
        ])
        .areas(area);

    let [_, middle, _] = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Percentage((100 - percent_x) / 2),
            Constraint::Percentage(percent_x),
            Constraint::Percentage((100 - percent_x) / 2),
        ])
        .areas(center);

    middle
}

fn render_progress(f: &mut Frame, progress: &LoadProgress, area: Rect) {
    let (label, ratio) = match progress {
        LoadProgress::GcRoots => ("Finding GC roots...".to_string(), 0.0),
        LoadProgress::PathInfo { done, total } => {
            let ratio = if *total == 0 {
                0.0
            } else {
                (*done as f64) / (*total as f64)
            };
            (format!("Loading path info... ({done}/{total})"), ratio)
        }
        LoadProgress::BuildGraph => ("Building dependency graph...".to_string(), 0.0),
        LoadProgress::Error(msg) => (format!("Error: {msg}"), 0.0),
    };

    let gauge = Gauge::default()
        .block(Block::default().borders(Borders::ALL))
        .gauge_style(Style::default().fg(Color::DarkGray))
        .label(Span::styled(label, Style::default().fg(Color::Reset)))
        .ratio(ratio);

    f.render_widget(gauge, area);
}

fn render_tree(f: &mut Frame, model: &GcRootModel, view: &mut ViewState, area: Rect) {
    view.visible_rows = area.height.saturating_sub(2);
    view.label.reset(view.tree.selected_id());

    let pending = view
        .key_handler
        .pending()
        .map(|p| format!("| {p} | "))
        .unwrap_or_default();

    let title = match view.pending_action {
        PendingAction::Delete => {
            format!(" Delete {} roots? (y/n) ", model.marked_count())
        }
        PendingAction::Reset => " Reset all marks? (y/n) ".to_string(),
        PendingAction::None => format!(
            " GC Roots | {} marked | profiles: {} {pending}",
            model.marked_count(),
            if model.show_profiles {
                "shown"
            } else {
                "hidden"
            }
        ),
    };

    let style = TreeListViewStyle {
        title: Some(Line::from(title)),
        line_style: Style::default().add_modifier(Modifier::BOLD),
        highlight_style: Style::default().add_modifier(Modifier::REVERSED | Modifier::BOLD),
        mark_style: Style::default().add_modifier(Modifier::CROSSED_OUT | Modifier::DIM),
        ..TreeListViewStyle::default()
    };

    let widget = TreeListView::new(model, &view.label, &view.columns, style);
    f.render_stateful_widget(widget, area, &mut view.tree);
}

fn render_ranger(f: &mut Frame, model: &GcRootModel, view: &mut ViewState, area: Rect) {
    view.visible_rows = area.height.saturating_sub(2);

    let chunks = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Ratio(1, 3),
            Constraint::Ratio(1, 3),
            Constraint::Ratio(1, 3),
        ])
        .split(area);

    let selected = view.tree.selected_id();
    let parent = selected.and_then(|id| model.parent(id));
    let grandparent = parent.and_then(|id| model.parent(id));

    let parent_siblings = grandparent.map(|p| model.children(p)).unwrap_or(&[]);
    let parent_idx = parent.and_then(|p| parent_siblings.iter().position(|&n| n == p));
    render_ranger_column(
        f,
        model,
        chunks[0],
        parent_siblings,
        parent_idx,
        Column::Left,
    );

    let siblings = parent.map(|p| model.children(p)).unwrap_or(&[]);
    let selected_idx = selected.and_then(|id| siblings.iter().position(|&n| n == id));
    render_ranger_column(f, model, chunks[1], siblings, selected_idx, Column::Middle);

    let children = selected.map(|id| model.children(id)).unwrap_or(&[]);
    render_ranger_column(f, model, chunks[2], children, None, Column::Right);
}

#[derive(Clone, Copy)]
enum Column {
    Left,
    Middle,
    Right,
}

fn render_ranger_column(
    f: &mut Frame,
    model: &GcRootModel,
    area: Rect,
    nodes: &[NodeIndex],
    selected: Option<usize>,
    column: Column,
) {
    let inner_width = area.width.saturating_sub(2) as usize;

    let items: Vec<ListItem> = nodes
        .iter()
        .enumerate()
        .map(|(i, &node)| {
            let name = model.name(node).unwrap_or("?");
            let closure_size = model.closure_size(node);
            let added_size = model.added_size(node);
            let has_children = !model.children(node).is_empty();

            let suffix = if has_children { "/" } else { "" };
            let size_str = if closure_size > 0 || added_size > 0 {
                format!(
                    "{} ({})",
                    format_size(closure_size),
                    format_size(added_size)
                )
            } else {
                String::new()
            };

            let is_marked = model.is_marked(node);
            let is_focused = matches!(column, Column::Middle);
            let is_selected = is_focused && selected == Some(i);

            let mut style = Style::default();
            if is_marked {
                style = style.add_modifier(Modifier::CROSSED_OUT | Modifier::DIM)
            }
            if is_focused && selected == Some(i) {
                style = style.add_modifier(Modifier::REVERSED | Modifier::BOLD)
            }

            let size_style = if is_selected {
                style
            } else {
                style.fg(Color::DarkGray)
            };

            let name_with_suffix = format!("{}{}", name, suffix);
            let name_len = name_with_suffix.chars().count();
            let size_len = size_str.chars().count();

            let padding = if name_len + size_len < inner_width {
                inner_width - name_len - size_len
            } else {
                1
            };

            let line = Line::from(vec![
                Span::styled(name_with_suffix, style),
                Span::styled(" ".repeat(padding), style),
                Span::styled(size_str, size_style),
            ]);
            ListItem::new(line)
        })
        .collect();

    let (borders, border_set) = match column {
        Column::Left => (
            Borders::LEFT | Borders::TOP | Borders::BOTTOM,
            border::PLAIN,
        ),
        Column::Middle => (
            Borders::LEFT | Borders::TOP | Borders::BOTTOM,
            border::Set {
                top_left: line::HORIZONTAL_DOWN,
                bottom_left: line::HORIZONTAL_UP,
                ..border::PLAIN
            },
        ),
        Column::Right => (
            Borders::ALL,
            border::Set {
                top_left: line::HORIZONTAL_DOWN,
                bottom_left: line::HORIZONTAL_UP,
                ..border::PLAIN
            },
        ),
    };

    let block = Block::default()
        .borders(borders)
        .border_set(border_set)
        .border_style(Style::default().fg(Color::White));

    let list = List::new(items).block(block);

    let mut state = ListState::default();
    state.select(selected);

    f.render_stateful_widget(list, area, &mut state);
}

fn ranger_select_child(view: &mut ViewState, model: &GcRootModel) -> Option<()> {
    let selected = view.tree.selected_id()?;
    let child = model.children(selected).first().copied()?;
    view.tree.select_by_id(model, child);
    Some(())
}

fn ranger_select_sibling(view: &mut ViewState, model: &GcRootModel, offset: isize) -> Option<()> {
    let selected = view.tree.selected_id()?;
    let parent = view.tree.selected_parent_id()?;
    let siblings = model.children(parent);
    let sibling = siblings.iter().position(|&n| n == selected)?;
    let sibling = sibling
        .saturating_add_signed(offset)
        .min(siblings.len() - 1);

    view.tree.select_by_id(model, siblings[sibling]);
    Some(())
}

fn ranger_move_left(view: &mut ViewState, model: &GcRootModel) {
    view.tree
        .handle_action(model, TreeAction::<()>::SelectParent);
}
