use std::{fmt::Display, ops::ControlFlow};

use rayon::iter::Either;
use tuirealm::event::{Key, KeyModifiers};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Command {
    Motion(Motion),
    Fold(Fold, Recurse, usize),
    Pending,
    Unhandled,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Motion {
    Up(usize),
    Down(usize),
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

#[derive(Debug, Clone, PartialEq, Eq)]
enum Pending {
    G,
    Z(usize),
    Count(usize),
}

#[derive(Debug, Default)]
pub struct KeyHandler {
    pending: Option<Pending>,
}

impl KeyHandler {
    pub fn pending(&self) -> Option<&dyn Display> {
        match &self.pending {
            Some(Pending::G) => Some(&"g"),
            Some(Pending::Z(..)) => Some(&"z"),
            Some(Pending::Count(count)) => Some(count),
            None => None,
        }
    }

    pub fn process(&mut self, modifiers: KeyModifiers, code: Key) -> Command {
        let count = match self.process_pending(modifiers, code) {
            Some(ControlFlow::Break(command)) => return command,
            Some(ControlFlow::Continue(count)) => count,
            None => 1,
        };

        use Key::*;
        match (modifiers, code) {
            (KeyModifiers::NONE, Char('j') | Down) => Command::Motion(Motion::Down(count)),
            (KeyModifiers::NONE, Char('k') | Up) => Command::Motion(Motion::Up(count)),
            // TODO: count
            (KeyModifiers::NONE, Char('h') | Left) => Command::Motion(Motion::Left),
            (KeyModifiers::NONE, Char('l') | Right) => Command::Motion(Motion::Right),
            (KeyModifiers::SHIFT, Char('G')) => Command::Motion(Motion::Last),
            // TODO: count (use down/up instead)
            (KeyModifiers::CONTROL, Char('u')) => Command::Motion(Motion::HalfPageUp),
            (KeyModifiers::CONTROL, Char('d')) => Command::Motion(Motion::HalfPageDown),
            (KeyModifiers::NONE, Char('g')) => {
                self.pending = Some(Pending::G);
                Command::Pending
            }
            (KeyModifiers::NONE, Char('z')) => {
                self.pending = Some(Pending::Z(count));
                Command::Pending
            }
            _ => Command::Unhandled,
        }
    }

    pub fn process_pending(
        &mut self,
        modifiers: KeyModifiers,
        code: Key,
    ) -> Option<ControlFlow<Command, usize>> {
        match self.pending.take() {
            Some(Pending::G) => match code {
                Key::Char('g') => Some(ControlFlow::Break(Command::Motion(Motion::First))),
                _ => None,
            },
            Some(Pending::Z(count)) => {
                Self::process_fold(modifiers, code, count).map(ControlFlow::Break)
            }
            Some(Pending::Count(count)) => self.process_count(modifiers, code, count),
            None => self.process_count(modifiers, code, 0),
        }
    }

    // TODO: count
    fn process_fold(modifiers: KeyModifiers, code: Key, count: usize) -> Option<Command> {
        use Fold::*;
        if modifiers & !KeyModifiers::SHIFT != KeyModifiers::NONE {
            return None;
        }
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
            count,
        ))
    }

    fn process_count(
        &mut self,
        modifiers: KeyModifiers,
        code: Key,
        count: usize,
    ) -> Option<ControlFlow<Command, usize>> {
        if modifiers != KeyModifiers::NONE {
            return None;
        }
        Some(match code {
            Key::Char(c @ '0'..='9') => {
                self.pending = Some(Pending::Count(
                    count
                        .saturating_mul(10)
                        .saturating_add((c as u8 - b'0') as usize),
                ));
                ControlFlow::Break(Command::Pending)
            }
            _ => ControlFlow::Continue(count),
        })
    }
}
