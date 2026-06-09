use crate::store_graph::DominatorGraph;

#[derive(Debug)]
pub struct EqHack(pub DominatorGraph);

impl PartialEq for EqHack {
    fn eq(&self, _: &Self) -> bool {
        false
    }
}

impl Eq for EqHack {}

#[derive(Debug, PartialEq)]
pub enum Msg {
    AppClose,
    LoadingComplete(EqHack),
    LoadingProgress(usize, usize),
    ToggleMark,
    ToggleProfiles,
    DeleteMarked,
    ResetMarks,
    ConfirmYes,
    ConfirmNo,
    SwitchView,
    None,
}

#[derive(Debug, Eq, PartialEq, Clone, Hash)]
pub enum Id {
    Tree,
    Ranger,
    Progress,
}
