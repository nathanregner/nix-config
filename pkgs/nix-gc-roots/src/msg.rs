use crate::cache::GcRootWithSize;

#[derive(Debug, PartialEq)]
pub enum Msg {
    AppClose,
    LoadingComplete(Vec<GcRootWithSize>),
    LoadingProgress(usize, usize),
    ToggleMark,
    ToggleProfiles,
    DeleteMarked,
    ResetMarks,
    ConfirmYes,
    ConfirmNo,
    None,
}

#[derive(Debug, Eq, PartialEq, Clone, Hash)]
pub enum Id {
    Tree,
    Progress,
}
