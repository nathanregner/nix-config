use ratatui::style::{Color, Style};
use ratatui::widgets::{Block, Borders, Gauge};
use tuirealm::command::{Cmd, CmdResult};
use tuirealm::component::{AppComponent, Component};
use tuirealm::event::{Event, Key, KeyModifiers, NoUserEvent};
use tuirealm::props::{AttrValue, Attribute, Props, QueryResult};
use tuirealm::ratatui::Frame;
use tuirealm::ratatui::layout::Rect;
use tuirealm::state::{State, StateValue};

use crate::msg::Msg;

pub struct ProgressInner {
    props: Props,
    current: usize,
    total: usize,
    message: String,
}

impl Default for ProgressInner {
    fn default() -> Self {
        Self {
            props: Props::default(),
            current: 0,
            total: 0,
            message: "Loading...".to_string(),
        }
    }
}

impl ProgressInner {
    pub fn new(message: &str, total: usize) -> Self {
        Self {
            props: Props::default(),
            current: 0,
            total,
            message: message.to_string(),
        }
    }

    pub fn set_progress(&mut self, current: usize, total: usize) {
        self.current = current;
        self.total = total;
    }

    fn ratio(&self) -> f64 {
        if self.total == 0 {
            0.0
        } else {
            (self.current as f64) / (self.total as f64)
        }
    }
}

impl Component for ProgressInner {
    fn view(&mut self, frame: &mut Frame, area: Rect) {
        let label = format!("{} ({}/{})", self.message, self.current, self.total);

        let gauge = Gauge::default()
            .block(
                Block::default()
                    .borders(Borders::ALL)
                    .title(" Loading GC Roots "),
            )
            .gauge_style(Style::default().fg(Color::Cyan))
            .ratio(self.ratio())
            .label(label);

        frame.render_widget(gauge, area);
    }

    fn query<'a>(&'a self, attr: Attribute) -> Option<QueryResult<'a>> {
        self.props.get_for_query(attr)
    }

    fn attr(&mut self, attr: Attribute, value: AttrValue) {
        self.props.set(attr, value);
    }

    fn state(&self) -> State {
        State::Single(StateValue::Usize(self.current))
    }

    fn perform(&mut self, cmd: Cmd) -> CmdResult {
        CmdResult::Invalid(cmd)
    }
}

#[derive(Component, Default)]
pub struct Progress {
    component: ProgressInner,
}

impl Progress {
    pub fn new(message: &str, total: usize) -> Self {
        Self {
            component: ProgressInner::new(message, total),
        }
    }
}

impl AppComponent<Msg, NoUserEvent> for Progress {
    fn on(&mut self, ev: &Event<NoUserEvent>) -> Option<Msg> {
        let key = ev.as_keyboard()?;
        match (key.modifiers, key.code) {
            (KeyModifiers::NONE, Key::Char('q') | Key::Esc)
            | (KeyModifiers::CONTROL, Key::Char('c')) => Some(Msg::AppClose),
            _ => None,
        }
    }
}
