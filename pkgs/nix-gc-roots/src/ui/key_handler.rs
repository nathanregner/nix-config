use tuirealm::event::{Key, KeyModifiers};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Motion {
    Up,
    Down,
    Left,
    Right,
    First,
    Last,
    HalfPageUp,
    HalfPageDown,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Command {
    Motion(Motion),
    Pending,
    Unhandled,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
enum PendingKey {
    #[default]
    None,
    G,
}

#[derive(Debug, Default)]
pub struct KeyHandler {
    pending: PendingKey,
}

impl KeyHandler {
    pub fn process(&mut self, modifiers: KeyModifiers, code: Key) -> Command {
        use Key::*;

        if self.pending == PendingKey::G {
            self.pending = PendingKey::None;
            if matches!((modifiers, code), (KeyModifiers::NONE, Key::Char('g'))) {
                return Command::Motion(Motion::First);
            }
            return Command::Unhandled;
        }

        match (modifiers, code) {
            (KeyModifiers::NONE, Char('j') | Down) => Command::Motion(Motion::Down),
            (KeyModifiers::NONE, Char('k') | Up) => Command::Motion(Motion::Up),
            (KeyModifiers::NONE, Char('h') | Left) => Command::Motion(Motion::Left),
            (KeyModifiers::NONE, Char('l') | Right) => Command::Motion(Motion::Right),
            (KeyModifiers::NONE, Char('G')) => Command::Motion(Motion::Last),
            (KeyModifiers::CONTROL, Char('u')) => Command::Motion(Motion::HalfPageUp),
            (KeyModifiers::CONTROL, Char('d')) => Command::Motion(Motion::HalfPageDown),
            (KeyModifiers::NONE, Char('g')) => {
                self.pending = PendingKey::G;
                Command::Pending
            }
            _ => Command::Unhandled,
        }
    }
}
