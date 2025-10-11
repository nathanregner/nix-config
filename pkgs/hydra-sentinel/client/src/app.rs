use tokio::sync::{oneshot, watch};
use tray_icon::{
    menu::{Menu, MenuEvent, MenuItem},
    TrayIcon, TrayIconBuilder,
};
use winit::{application::ApplicationHandler, event_loop::EventLoop};

use crate::ConnectionState;

#[derive(Debug)]
pub enum UserEvent {
    MenuEvent(MenuEvent),
    StateChange(State),
    Exit,
}

#[derive(PartialEq, Eq, Clone, Copy, Debug)]
struct State {
    enabled: bool,
    connection_state: ConnectionState,
}

const TOGGLE: &str = "TOGGLE";

pub struct Application {
    tray_icon: Option<TrayIcon>,
    enabled: watch::Sender<bool>,
    state: State,
}

impl Application {
    pub fn run(
        mut shutdown_rx: oneshot::Receiver<()>,
        mut connection_state: watch::Receiver<ConnectionState>,
        enabled: watch::Sender<bool>,
    ) -> anyhow::Result<()> {
        let event_loop = EventLoop::<UserEvent>::with_user_event().build().unwrap();
        let mut app = Application {
            tray_icon: None,
            enabled: enabled.clone(),
            state: State {
                enabled: *enabled.borrow(),
                connection_state: *connection_state.borrow(),
            },
        };

        let mut enabled = enabled.subscribe();
        let proxy = event_loop.create_proxy();
        tokio::task::spawn(async move {
            loop {
                tokio::select! {
                    _ = &mut shutdown_rx => {
                        let _ = proxy.send_event(UserEvent::Exit);
                        break;
                    }
                    _ = connection_state.changed() => {},
                    _ = enabled.changed() => {},
                };
                if let Err(err) = proxy.send_event(UserEvent::StateChange(State {
                    enabled: *enabled.borrow(),
                    connection_state: *connection_state.borrow(),
                })) {
                    tracing::error!("Failed to send event: {err}");
                }
            }
        });

        // let proxy = event_loop.create_proxy();
        // TrayIconEvent::set_event_handler(Some(move |event| {
        //     if let Err(err) = proxy.send_event(UserEvent::TrayIconEvent(event)) {
        //         tracing::error!("Failed to proxy TrayIconEvent: {}", err);
        //     }
        // }));

        let proxy = event_loop.create_proxy();
        MenuEvent::set_event_handler(Some(move |event| {
            if let Err(err) = proxy.send_event(UserEvent::MenuEvent(event)) {
                tracing::error!("Failed to proxy MenuEvent: {}", err);
            }
        }));

        event_loop.run_app(&mut app)?;
        Ok(())
    }

    fn new_tray_icon(&self) -> TrayIcon {
        let path = concat!(env!("CARGO_MANIFEST_DIR"), "/src/output.png");
        let icon = load_icon(std::path::Path::new(path));

        TrayIconBuilder::new()
            .with_menu(Box::new(self.new_tray_menu().unwrap()))
            .with_tooltip("Hydra Sentinel")
            .with_icon(icon)
            .build()
            .unwrap()
    }

    fn new_tray_menu(&self) -> anyhow::Result<Menu> {
        let menu = Menu::new();
        let toggle = if self.state.enabled {
            MenuItem::with_id(TOGGLE, "Disable", true, None)
        } else {
            MenuItem::with_id(TOGGLE, "Enable", true, None)
        };
        menu.append(&toggle)?;
        menu.append(&MenuItem::new("Connection state", false, None))?;
        Ok(menu)
    }
}

impl ApplicationHandler<UserEvent> for Application {
    fn resumed(&mut self, _event_loop: &winit::event_loop::ActiveEventLoop) {}

    fn window_event(
        &mut self,
        _event_loop: &winit::event_loop::ActiveEventLoop,
        _window_id: winit::window::WindowId,
        _event: winit::event::WindowEvent,
    ) {
    }

    fn new_events(
        &mut self,
        _event_loop: &winit::event_loop::ActiveEventLoop,
        cause: winit::event::StartCause,
    ) {
        // We create the icon once the event loop is actually running
        // to prevent issues like https://github.com/tauri-apps/tray-icon/issues/90
        if winit::event::StartCause::Init == cause {
            #[cfg(not(target_os = "linux"))]
            {
                self.tray_icon = Some(self.new_tray_icon());
            }

            // We have to request a redraw here to have the icon actually show up.
            // Winit only exposes a redraw method on the Window so we use core-foundation directly.
            #[cfg(target_os = "macos")]
            {
                use objc2_core_foundation::{CFRunLoopGetMain, CFRunLoopWakeUp};

                let rl = CFRunLoopGetMain().unwrap();
                CFRunLoopWakeUp(&rl);
            }
        }
    }

    fn user_event(&mut self, event_loop: &winit::event_loop::ActiveEventLoop, event: UserEvent) {
        match event {
            UserEvent::MenuEvent(MenuEvent { id }) if id == TOGGLE => {
                tracing::debug!("Toggled");
                self.enabled.send_modify(|enabled| {
                    *enabled = !*enabled;
                });
            }
            UserEvent::MenuEvent(_) => {
                tracing::warn!("Unhandled menu event");
            }
            UserEvent::StateChange(state) => {
                if state != self.state {
                    self.state = state;
                    tracing::debug!("State changed");
                    let menu = self.new_tray_menu().unwrap();
                    if let Some(tray_icon) = &mut self.tray_icon {
                        tray_icon.set_menu(Some(Box::new(menu)));
                    }
                }
            }
            UserEvent::Exit => {
                tracing::debug!("Exiting");
                event_loop.exit();
            }
        }
    }
}

fn load_icon(path: &std::path::Path) -> tray_icon::Icon {
    let (icon_rgba, icon_width, icon_height) = {
        let image = image::open(path)
            .expect("Failed to open icon path")
            .into_rgba8();
        let (width, height) = image.dimensions();
        let rgba = image.into_raw();
        (rgba, width, height)
    };
    tray_icon::Icon::from_rgba(icon_rgba, icon_width, icon_height).expect("Failed to open icon")
}
