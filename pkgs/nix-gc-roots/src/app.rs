use std::error::Error;
use std::time::Duration;

use anyhow::Result;
use tuirealm::application::Application;
use tuirealm::event::NoUserEvent;
use tuirealm::listener::EventListenerCfg;
use tuirealm::ratatui::layout::{Constraint, Direction, Layout};
use tuirealm::terminal::{CrosstermTerminalAdapter, TerminalAdapter, TerminalResult};

use crate::components::{Progress, TreeView};
use crate::msg::{Id, Msg};

#[derive(Clone, Copy, PartialEq)]
pub enum AppView {
    Loading,
    Tree,
}

pub struct Model<T>
where
    T: TerminalAdapter,
{
    pub app: Application<Id, Msg, NoUserEvent>,
    pub quit: bool,
    pub redraw: bool,
    pub view: AppView,
    pub terminal: T,
}

impl Default for Model<CrosstermTerminalAdapter> {
    fn default() -> Self {
        Self {
            app: Self::init_app().expect("Failed to initialize application"),
            quit: false,
            redraw: true,
            view: AppView::Loading,
            terminal: Self::init_adapter().expect("Cannot initialize terminal"),
        }
    }
}

impl Model<CrosstermTerminalAdapter> {
    fn init_adapter() -> TerminalResult<CrosstermTerminalAdapter> {
        let mut adapter = CrosstermTerminalAdapter::new()?;
        adapter.enable_raw_mode()?;
        adapter.enter_alternate_screen()?;
        Ok(adapter)
    }
}

impl<T> Model<T>
where
    T: TerminalAdapter,
{
    pub fn view(&mut self) {
        let _ = self.terminal.draw(|f| {
            let area = f.area();

            match self.view {
                AppView::Loading => {
                    let [_, center, _] = Layout::default()
                        .direction(Direction::Vertical)
                        .constraints([
                            Constraint::Percentage(40),
                            Constraint::Length(3),
                            Constraint::Percentage(40),
                        ])
                        .areas(area);

                    let [_, middle, _] = Layout::default()
                        .direction(Direction::Horizontal)
                        .constraints([
                            Constraint::Percentage(20),
                            Constraint::Percentage(60),
                            Constraint::Percentage(20),
                        ])
                        .areas(center);

                    self.app.view(&Id::Progress, f, middle);
                }
                AppView::Tree => {
                    self.app.view(&Id::Tree, f, area);
                }
            }
        });
    }

    pub fn update(&mut self, msg: Msg) {
        self.redraw = true;

        match msg {
            Msg::AppClose => {
                self.quit = true;
            }
            Msg::LoadingComplete(roots) => {
                let _ = self.app.umount(&Id::Progress);
                let _ = self
                    .app
                    .mount(Id::Tree, Box::new(TreeView::new(roots)), vec![]);
                let _ = self.app.active(&Id::Tree);
                self.view = AppView::Tree;
            }
            Msg::LoadingProgress(_current, _total) => {
                // Progress updates handled by Progress component directly
            }
            Msg::ConfirmYes => {
                // // Tree handles this internally and reloads
                // // For now, just trigger a reload
                // if let Ok(roots) = self.load_roots() {
                //     let _ = self.app.umount(&Id::Tree);
                //     let _ = self
                //         .app
                //         .mount(Id::Tree, Box::new(TreeView::new(roots)), vec![]);
                //     let _ = self.app.active(&Id::Tree);
                // }
            }
            Msg::ToggleMark
            | Msg::ToggleProfiles
            | Msg::DeleteMarked
            | Msg::ResetMarks
            | Msg::ConfirmNo
            | Msg::None => {
                // These are handled by the TreeView component itself
            }
        }
    }

    fn init_app() -> Result<Application<Id, Msg, NoUserEvent>, Box<dyn Error>> {
        let mut app: Application<Id, Msg, NoUserEvent> = Application::init(
            EventListenerCfg::default().crossterm_input_listener(Duration::from_millis(0), 0),
        );

        app.mount(
            Id::Progress,
            Box::new(Progress::new("Loading GC roots", 0)),
            vec![],
        )?;
        app.active(&Id::Progress)?;

        Ok(app)
    }

    pub fn load_roots(&mut self) -> Result<()> {
        todo!()
        // let roots = nix::gc_roots()?;
        // // TODO: base_dirs
        // let cache = Cache::new(&PathBuf::from("/home/nregner/.cache/nix-gc-roots"))?;
        // let roots = cache.get_sizes roots)?;
        // self.update(Msg::LoadingComplete(roots));
        // Ok(())
    }
}
