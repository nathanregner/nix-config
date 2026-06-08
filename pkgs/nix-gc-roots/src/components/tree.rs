use std::cell::Cell as StdCell;

use petgraph::graph::NodeIndex;
use ratatui::layout::Constraint;
use ratatui::style::{Color, Modifier, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::Cell;
use tui_treelistview::{
    ColumnDef, SimpleColumns, TreeAction, TreeGlyphs, TreeLabelRenderer, TreeListView,
    TreeListViewState, TreeListViewStyle, TreeModel, TreeRowContext,
};
use tuirealm::command::{Cmd, CmdResult};
use tuirealm::component::{AppComponent, Component};
use tuirealm::event::{Event, Key, KeyEvent, KeyModifiers, NoUserEvent};
use tuirealm::props::{AttrValue, Attribute, Props, QueryResult};
use tuirealm::ratatui::Frame;
use tuirealm::ratatui::layout::Rect;
use tuirealm::state::{State, StateValue};

use crate::model::{GcRootModel, format_size, is_direnv_path};
use crate::msg::Msg;
use crate::store_graph::DominatorGraph;

#[derive(Clone, Copy, PartialEq)]
pub enum PendingAction {
    None,
    Delete,
    Reset,
}

struct Label {
    current_row: StdCell<usize>,
    selected_id: StdCell<Option<NodeIndex>>,
    selected_row: StdCell<Option<usize>>,
}

impl Label {
    fn new() -> Self {
        Self {
            current_row: StdCell::new(0),
            selected_id: StdCell::new(None),
            selected_row: StdCell::new(None),
        }
    }

    fn reset(&self, selected_id: Option<NodeIndex>) {
        self.current_row.set(0);
        self.selected_id.set(selected_id);
        self.selected_row.set(None);
    }
}

impl TreeLabelRenderer<GcRootModel> for Label {
    fn cell<'a>(
        &'a self,
        model: &'a GcRootModel,
        id: NodeIndex,
        ctx: &TreeRowContext,
        glyphs: &TreeGlyphs<'a>,
    ) -> Cell<'a> {
        let name = model.name(id).unwrap_or("");
        let is_marked = model.is_marked(id);

        let mut spans: Vec<Span<'a>> = Vec::new();

        let row = self.current_row.get();
        self.current_row.set(row + 1);

        let is_selected = self.selected_id.get() == Some(id);
        if is_selected {
            self.selected_row.set(Some(row));
        }

        let line_num = if is_selected {
            format!("{:>3} ", row)
        } else if let Some(sel_row) = self.selected_row.get() {
            let diff = (row as isize - sel_row as isize).abs();
            format!("{:>3} ", diff)
        } else {
            format!("{:>3} ", row)
        };
        spans.push(Span::styled(line_num, Style::default().fg(Color::DarkGray)));

        if ctx.level > 0 && ctx.render.draw_lines {
            for (l, is_last) in ctx.is_tail_stack.iter().enumerate() {
                let part = if l == (ctx.level as usize) - 1 {
                    if *is_last {
                        glyphs.branch_last
                    } else {
                        glyphs.branch
                    }
                } else if *is_last {
                    glyphs.indent
                } else {
                    glyphs.vert
                };
                spans.push(Span::styled(part, ctx.line_style));
            }
        } else if ctx.level > 0 {
            for _ in 0..ctx.level {
                spans.push(Span::raw(glyphs.empty));
            }
        }

        let expander = if ctx.node.has_children {
            if ctx.node.is_expanded {
                glyphs.expanded
            } else {
                glyphs.collapsed
            }
        } else if ctx.level == 0 {
            ""
        } else {
            glyphs.leaf
        };
        if !expander.is_empty() {
            spans.push(Span::raw(expander));
            spans.push(Span::raw(" "));
        }

        let name_style = if is_marked {
            Style::default().add_modifier(Modifier::CROSSED_OUT | Modifier::DIM)
        } else {
            Style::default()
        };
        spans.push(Span::styled(name.to_string(), name_style));

        Cell::from(Line::from(spans))
    }
}

fn marked_style(model: &GcRootModel, id: NodeIndex) -> Style {
    if model.is_marked(id) {
        Style::default().add_modifier(Modifier::CROSSED_OUT | Modifier::DIM)
    } else {
        Style::default()
    }
}

fn size_cell(model: &GcRootModel, id: NodeIndex) -> Cell<'_> {
    let size = model.closure_size(id);
    if size == 0 {
        Cell::from("")
    } else {
        Cell::from(format_size(size)).style(marked_style(model, id))
    }
}

pub struct TreeViewInner {
    props: Props,
    model: GcRootModel,
    state: TreeListViewState<NodeIndex>,
    label: Label,
    columns: SimpleColumns<1, GcRootModel>,
    pending_action: PendingAction,
    pending_g: bool,
}

fn make_columns() -> SimpleColumns<1, GcRootModel> {
    SimpleColumns::new(
        Constraint::Fill(1),
        "Name",
        [ColumnDef::new("Size", Constraint::Length(8), size_cell)],
    )
    .header_style(
        Style::default()
            .fg(Color::Yellow)
            .add_modifier(Modifier::BOLD),
    )
}

impl TreeViewInner {
    pub fn with_graph(graph: DominatorGraph) -> Self {
        let model = GcRootModel::new(graph);
        let mut state = TreeListViewState::with_capacity(model.size_hint());

        for ni in model.graph.node_indices() {
            if let Some(path) = model.path(ni) {
                let children = model.children(ni);
                if !children.is_empty() && !is_direnv_path(path) {
                    state.set_expanded(ni, model.root_id, true);
                }
            }
        }

        if let Some(root_id) = model.root_id {
            let children = model.children(root_id);
            if !children.is_empty() {
                state.select_by_id(&model, children[0]);
            }
        }

        Self {
            props: Props::default(),
            model,
            state,
            label: Label::new(),
            columns: make_columns(),
            pending_action: PendingAction::None,
            pending_g: false,
        }
    }

    fn style(&self) -> TreeListViewStyle<'static> {
        let title = match self.pending_action {
            PendingAction::Delete => {
                format!(" Delete {} roots? (y/n) ", self.model.marked_count())
            }
            PendingAction::Reset => " Reset all marks? (y/n) ".to_string(),
            PendingAction::None => format!(
                " GC Roots | {} marked | profiles: {} | d:mark r:reset D:delete q:quit ",
                self.model.marked_count(),
                if self.model.show_profiles {
                    "shown"
                } else {
                    "hidden"
                }
            ),
        };

        TreeListViewStyle {
            title: Some(Line::from(title)),
            highlight_style: Style::default().bg(Color::Blue).fg(Color::Black),
            mark_style: Style::default().fg(Color::Red),
            ..TreeListViewStyle::default()
        }
    }
}

impl Component for TreeViewInner {
    fn view(&mut self, frame: &mut Frame, area: Rect) {
        self.label.reset(self.state.selected_id());
        let style = self.style();
        let widget = TreeListView::new(&self.model, &self.label, &self.columns, style);
        frame.render_stateful_widget(widget, area, &mut self.state);
    }

    fn query<'a>(&'a self, attr: Attribute) -> Option<QueryResult<'a>> {
        self.props.get_for_query(attr)
    }

    fn attr(&mut self, attr: Attribute, value: AttrValue) {
        self.props.set(attr, value);
    }

    fn state(&self) -> State {
        State::Single(StateValue::Usize(self.model.marked_count()))
    }

    fn perform(&mut self, cmd: Cmd) -> CmdResult {
        match cmd {
            Cmd::Custom("reload") => CmdResult::NoChange,
            _ => CmdResult::Invalid(cmd),
        }
    }
}

#[derive(Component)]
pub struct TreeView {
    component: TreeViewInner,
}

impl TreeView {
    pub fn new(graph: DominatorGraph) -> Self {
        Self {
            component: TreeViewInner::with_graph(graph),
        }
    }
}

impl AppComponent<Msg, NoUserEvent> for TreeView {
    fn on(&mut self, ev: &Event<NoUserEvent>) -> Option<Msg> {
        let inner = &mut self.component;

        let key = ev.as_keyboard()?;

        if inner.pending_action != PendingAction::None {
            match key {
                KeyEvent {
                    code: Key::Char('y'),
                    ..
                }
                | KeyEvent {
                    code: Key::Char('Y'),
                    ..
                } => {
                    let action = inner.pending_action;
                    inner.pending_action = PendingAction::None;
                    return match action {
                        PendingAction::Delete => Some(Msg::ConfirmYes),
                        PendingAction::Reset => {
                            inner.model.reset_marks();
                            Some(Msg::None)
                        }
                        PendingAction::None => None,
                    };
                }
                _ => {
                    inner.pending_action = PendingAction::None;
                    return Some(Msg::ConfirmNo);
                }
            }
        }

        match key {
            KeyEvent {
                code: Key::Char('q'),
                ..
            }
            | KeyEvent { code: Key::Esc, .. } => Some(Msg::AppClose),

            KeyEvent {
                code: Key::Char('g'),
                modifiers: KeyModifiers::NONE,
            } => {
                if inner.pending_g {
                    inner
                        .state
                        .handle_action(&inner.model, TreeAction::<()>::SelectFirst);
                    inner.pending_g = false;
                } else {
                    inner.pending_g = true;
                }
                Some(Msg::None)
            }

            KeyEvent {
                code: Key::Char('G'),
                ..
            } => {
                inner
                    .state
                    .handle_action(&inner.model, TreeAction::<()>::SelectLast);
                inner.pending_g = false;
                Some(Msg::None)
            }

            KeyEvent {
                code: Key::Char('h'),
                ..
            }
            | KeyEvent {
                code: Key::Left, ..
            } => {
                if let Some(id) = inner.state.selected_id() {
                    inner.state.set_expanded(id, inner.model.root_id, false);
                }
                inner
                    .state
                    .handle_action(&inner.model, TreeAction::<()>::SelectParent);
                inner.pending_g = false;
                Some(Msg::None)
            }

            KeyEvent {
                code: Key::Char('l'),
                ..
            }
            | KeyEvent {
                code: Key::Right, ..
            } => {
                if let Some(id) = inner.state.selected_id() {
                    inner.state.set_expanded(id, inner.model.root_id, true);
                }
                inner
                    .state
                    .handle_action(&inner.model, TreeAction::<()>::SelectChild);
                inner.pending_g = false;
                Some(Msg::None)
            }

            KeyEvent {
                code: Key::Char('j'),
                ..
            }
            | KeyEvent {
                code: Key::Down, ..
            } => {
                inner
                    .state
                    .handle_action(&inner.model, TreeAction::<()>::SelectNext);
                inner.pending_g = false;
                Some(Msg::None)
            }

            KeyEvent {
                code: Key::Char('k'),
                ..
            }
            | KeyEvent { code: Key::Up, .. } => {
                inner
                    .state
                    .handle_action(&inner.model, TreeAction::<()>::SelectPrev);
                inner.pending_g = false;
                Some(Msg::None)
            }

            KeyEvent {
                code: Key::Char('d'),
                modifiers: KeyModifiers::NONE,
            } => {
                if let Some(id) = inner.state.selected_id() {
                    inner.model.toggle_mark(id);
                }
                inner.pending_g = false;
                Some(Msg::ToggleMark)
            }

            KeyEvent {
                code: Key::Char('D'),
                ..
            } => {
                if inner.model.marked_count() > 0 {
                    inner.pending_action = PendingAction::Delete;
                }
                inner.pending_g = false;
                Some(Msg::DeleteMarked)
            }

            KeyEvent {
                code: Key::Char('r'),
                modifiers: KeyModifiers::NONE,
            } => {
                if inner.model.marked_count() > 0 {
                    inner.pending_action = PendingAction::Reset;
                }
                inner.pending_g = false;
                Some(Msg::ResetMarks)
            }

            KeyEvent {
                code: Key::Char('p'),
                modifiers: KeyModifiers::NONE,
            } => {
                inner.model.toggle_profiles();
                inner.state.invalidate_all();
                inner.pending_g = false;
                Some(Msg::ToggleProfiles)
            }

            _ => {
                inner.pending_g = false;
                None
            }
        }
    }
}
