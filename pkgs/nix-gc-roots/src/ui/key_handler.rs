use tuirealm::event::{Key, KeyModifiers};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Command {
    Motion(Motion),
    Fold(Fold, Recurse),
    Pending,
    Unhandled,
}

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
pub enum Fold {
    Open,
    Close,
    Alternate,
    Reduce,
    More,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Recurse {
    Yes,
    No,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum PendingKey {
    G,
    Z,
}

#[derive(Debug, Default)]
pub struct KeyHandler {
    pending: Option<PendingKey>,
}

impl KeyHandler {
    pub fn pending(&self) -> Option<&'static str> {
        match self.pending {
            Some(PendingKey::G) => Some("g"),
            Some(PendingKey::Z) => Some("z"),
            None => None,
        }
    }

    pub fn process(&mut self, modifiers: KeyModifiers, code: Key) -> Command {
        if let Some(command) = self.process_pending(modifiers, code) {
            return command;
        }

        use Key::*;
        match (modifiers, code) {
            (KeyModifiers::NONE, Char('j') | Down) => Command::Motion(Motion::Down),
            (KeyModifiers::NONE, Char('k') | Up) => Command::Motion(Motion::Up),
            (KeyModifiers::NONE, Char('h') | Left) => Command::Motion(Motion::Left),
            (KeyModifiers::NONE, Char('l') | Right) => Command::Motion(Motion::Right),
            (KeyModifiers::SHIFT, Char('G')) => Command::Motion(Motion::Last),
            (KeyModifiers::CONTROL, Char('u')) => Command::Motion(Motion::HalfPageUp),
            (KeyModifiers::CONTROL, Char('d')) => Command::Motion(Motion::HalfPageDown),
            (KeyModifiers::NONE, Char('g')) => {
                self.pending = Some(PendingKey::G);
                Command::Pending
            }
            (KeyModifiers::NONE, Char('z')) => {
                self.pending = Some(PendingKey::Z);
                Command::Pending
            }
            _ => Command::Unhandled,
        }
    }

    pub fn process_pending(&mut self, modifiers: KeyModifiers, code: Key) -> Option<Command> {
        let pending = self.pending.take();
        if modifiers & !KeyModifiers::SHIFT != KeyModifiers::NONE {
            return None;
        }

        match pending? {
            PendingKey::G => match code {
                Key::Char('g') => Some(Command::Motion(Motion::First)),
                _ => None,
            },
            PendingKey::Z => Self::process_fold(modifiers, code),
        }
    }

    fn process_fold(modifiers: KeyModifiers, code: Key) -> Option<Command> {
        use Fold::*;
        let Key::Char(char) = code else {
            return None;
        };
        let fold = match char.to_ascii_lowercase() {
            'o' => Open,
            'c' => Close,
            'a' => Alternate,
            'r' => Reduce,
            'm' => More,
            _ => return None,
        };

        Some(Command::Fold(
            fold,
            if modifiers == KeyModifiers::SHIFT {
                Recurse::Yes
            } else {
                Recurse::No
            },
        ))
    }
}
