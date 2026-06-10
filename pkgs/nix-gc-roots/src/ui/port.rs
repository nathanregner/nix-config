use std::time::Duration;

use crossterm::event::{self as xterm, Event as XtermEvent, KeyEventKind};
use tuirealm::event::{Event, KeyEvent, NoUserEvent};
use tuirealm::listener::{Poll, PortError, PortResult};

/// TODO: upstream
///
/// Custom input listener that blocks until events are available with no sleep.
pub struct BlockingInputListener;

impl Poll<NoUserEvent> for BlockingInputListener {
    fn poll(&mut self) -> PortResult<Option<Event<NoUserEvent>>> {
        match xterm::poll(Duration::from_secs(1)) {
            Ok(true) => match xterm::read() {
                Ok(ev) => Ok(Some(convert_event(ev))),
                Err(e) => Err(PortError::IntermittentError(e.to_string())),
            },
            Ok(false) => Ok(None),
            Err(e) => Err(PortError::IntermittentError(e.to_string())),
        }
    }
}

fn convert_event(e: XtermEvent) -> Event<NoUserEvent> {
    match e {
        XtermEvent::Key(key) if key.kind == KeyEventKind::Press => {
            Event::Keyboard(KeyEvent::from(key))
        }
        XtermEvent::Key(_) => Event::None,
        XtermEvent::Resize(w, h) => Event::WindowResize(w, h),
        XtermEvent::FocusGained => Event::FocusGained,
        XtermEvent::FocusLost => Event::FocusLost,
        XtermEvent::Paste(clipboard) => Event::Paste(clipboard),
        XtermEvent::Mouse(ev) => Event::Mouse(ev.into()),
    }
}
