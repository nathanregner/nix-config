use petgraph::graph::NodeIndex;
use ratatui::layout::{Constraint, Direction, Layout, Rect};
use ratatui::style::{Color, Modifier, Style};
use ratatui::symbols::{border, line};
use ratatui::text::{Line, Span};
use ratatui::widgets::{Block, Borders, List, ListItem, ListState};
use tuirealm::command::{Cmd, CmdResult};
use tuirealm::component::{AppComponent, Component};
use tuirealm::event::{Event, Key, KeyModifiers, NoUserEvent};
use tuirealm::props::{AttrValue, Attribute, Props, QueryResult};
use tuirealm::ratatui::Frame;
use tuirealm::state::{State, StateValue};

use crate::msg::Msg;
use crate::store_graph::DominatorGraph;
use crate::ui::key_handler::KeyHandler;
use crate::ui::{GcRootModel, format_size};

pub struct RangerViewInner {
    props: Props,
    model: GcRootModel,
    current: NodeIndex,
    selected_index: usize,
    key_handler: KeyHandler,
    visible_rows: u16,
}

impl RangerViewInner {
    pub fn new(graph: DominatorGraph) -> Self {
        let model = GcRootModel::new(graph);
        let root = model.root_id.unwrap_or(NodeIndex::new(0));
        let current = model.children(root).first().copied().unwrap_or(root);

        Self {
            props: Props::default(),
            model,
            current,
            selected_index: 0,
            key_handler: Default::default(),
            visible_rows: 20,
        }
    }

    fn parent(&self) -> Option<NodeIndex> {
        self.model.parent(self.current)
    }

    fn siblings(&self) -> &[NodeIndex] {
        if let Some(parent) = self.parent() {
            self.model.children(parent)
        } else {
            std::slice::from_ref(&self.current)
        }
    }

    fn current_children(&self) -> &[NodeIndex] {
        self.model.children(self.current)
    }

    fn selected_child(&self) -> Option<NodeIndex> {
        self.current_children().get(self.selected_index).copied()
    }

    fn child_children(&self) -> &[NodeIndex] {
        if let Some(child) = self.selected_child() {
            self.model.children(child)
        } else {
            &[]
        }
    }

    fn move_up(&mut self, count: usize) {
        self.selected_index = self.selected_index.saturating_sub(count);
    }

    fn move_down(&mut self, count: usize) {
        let children = self.current_children();
        if !children.is_empty() {
            self.selected_index = (self.selected_index + count).min(children.len() - 1);
        }
    }

    fn move_left(&mut self) {
        if let Some(parent) = self.parent() {
            let grandparent_children = if let Some(gp) = self.model.parent(parent) {
                self.model.children(gp)
            } else {
                std::slice::from_ref(&parent)
            };
            self.selected_index = grandparent_children
                .iter()
                .position(|&n| n == self.current)
                .unwrap_or(0);
            self.current = parent;
        }
    }

    fn move_right(&mut self) {
        if let Some(child) = self.selected_child() {
            self.current = child;
            self.selected_index = 0;
        }
    }

    fn move_first(&mut self) {
        self.selected_index = 0;
    }

    fn move_last(&mut self) {
        let children = self.current_children();
        if !children.is_empty() {
            self.selected_index = children.len() - 1;
        }
    }

    fn render_column(
        &self,
        frame: &mut Frame,
        area: Rect,
        nodes: &[NodeIndex],
        selected: Option<usize>,
        position: ColumnPosition,
    ) {
        let inner_width = area.width.saturating_sub(2) as usize;

        let items: Vec<ListItem> = nodes
            .iter()
            .enumerate()
            .map(|(i, &node)| {
                let name = self.model.name(node).unwrap_or("?");
                let closure_size = self.model.closure_size(node);
                let added_size = self.model.added_size(node);
                let has_children = !self.model.children(node).is_empty();

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

                let is_marked = self.model.is_marked(node);
                let is_focused = matches!(position, ColumnPosition::Middle);
                let is_selected = is_focused && selected == Some(i);

                let mut style = Style::default();
                if is_marked {
                    style = style.add_modifier(Modifier::CROSSED_OUT | Modifier::DIM)
                }
                // TODO: also highlight parent
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

        let (borders, border_set) = match position {
            ColumnPosition::Left => (
                Borders::LEFT | Borders::TOP | Borders::BOTTOM,
                border::PLAIN,
            ),
            ColumnPosition::Middle => (
                Borders::LEFT | Borders::TOP | Borders::BOTTOM,
                border::Set {
                    top_left: line::HORIZONTAL_DOWN,
                    bottom_left: line::HORIZONTAL_UP,
                    ..border::PLAIN
                },
            ),
            ColumnPosition::Right => (
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

        frame.render_stateful_widget(list, area, &mut state);
    }
}

#[derive(Clone, Copy)]
enum ColumnPosition {
    Left,
    Middle,
    Right,
}

impl Component for RangerViewInner {
    fn view(&mut self, frame: &mut Frame, area: Rect) {
        self.visible_rows = area.height.saturating_sub(2);
        let chunks = Layout::default()
            .direction(Direction::Horizontal)
            .constraints([
                Constraint::Ratio(1, 3),
                Constraint::Ratio(1, 3),
                Constraint::Ratio(1, 3),
            ])
            .split(area);

        let siblings = self.siblings();
        let current_idx = siblings.iter().position(|&n| n == self.current);
        self.render_column(
            frame,
            chunks[0],
            siblings,
            current_idx,
            ColumnPosition::Left,
        );

        let children = self.current_children();
        self.render_column(
            frame,
            chunks[1],
            children,
            Some(self.selected_index),
            ColumnPosition::Middle,
        );

        let child_children = self.child_children();
        self.render_column(
            frame,
            chunks[2],
            child_children,
            None,
            ColumnPosition::Right,
        );
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
pub struct RangerView {
    component: RangerViewInner,
}

impl RangerView {
    pub fn new(graph: DominatorGraph) -> Self {
        Self {
            component: RangerViewInner::new(graph),
        }
    }
}

impl AppComponent<Msg, NoUserEvent> for RangerView {
    fn on(&mut self, ev: &Event<NoUserEvent>) -> Option<Msg> {
        let inner = &mut self.component;
        let key = ev.as_keyboard()?;

        use super::key_handler::{Command, Motion};
        match inner.key_handler.process(key.modifiers, key.code) {
            Command::Motion(motion) => {
                match motion {
                    Motion::Up => inner.move_up(1),
                    Motion::Down => inner.move_down(1),
                    Motion::HalfPageUp => inner.move_up(inner.visible_rows.div_ceil(2) as usize),
                    Motion::HalfPageDown => {
                        inner.move_down(inner.visible_rows.div_ceil(2) as usize)
                    }
                    Motion::Left => inner.move_left(),
                    Motion::Right => inner.move_right(),
                    Motion::First => inner.move_first(),
                    Motion::Last => inner.move_last(),
                }
                return Some(Msg::None);
            }
            Command::Fold(..) | Command::Pending => return Some(Msg::None),
            Command::Unhandled => {}
        }

        use Key::*;
        match (key.modifiers, key.code) {
            (_, Char('q')) | (_, Esc) | (KeyModifiers::CONTROL, Char('c')) => {
                return Some(Msg::AppClose);
            }
            (_, Char('d')) => {
                if let Some(child) = inner.selected_child() {
                    inner.model.toggle_mark(child);
                }
                return Some(Msg::None);
            }
            (_, Char('r')) => {
                inner.model.reset_marks();
                return Some(Msg::None);
            }
            (_, Tab) => return Some(Msg::SwitchView),
            _ => {}
        }

        None
    }
}
