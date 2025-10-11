use tao::{
    event::Event,
    event_loop::{ControlFlow, EventLoopBuilder},
};
use tokio::sync::{oneshot, watch};
use tray_icon::{
    menu::{ContextMenu, Menu, MenuEvent, MenuItem},
    Icon, TrayIcon, TrayIconBuilder,
};

use crate::ConnectionState;

#[derive(Debug)]
pub enum UserEvent {
    MenuEvent(MenuEvent),
    StateChange,
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
        connection_state: watch::Receiver<ConnectionState>,
        enabled: watch::Sender<bool>,
    ) -> anyhow::Result<()> {
        let event_loop = EventLoopBuilder::<UserEvent>::with_user_event().build();

        tokio::task::spawn({
            let mut enabled = enabled.subscribe();
            let mut connection_state = connection_state.clone();
            let proxy = event_loop.create_proxy();
            async move {
                loop {
                    tokio::select! {
                        _ = &mut shutdown_rx => {
                            let _ = proxy.send_event(UserEvent::Exit);
                            break;
                        }
                        _ = connection_state.changed() => {},
                        _ = enabled.changed() => {},
                    };
                    if let Err(err) = proxy.send_event(UserEvent::StateChange) {
                        tracing::error!("Failed to send event: {err}");
                    }
                }
            }
        });

        let tray_menu = Menu::new();
        let toggle = MenuItem::new("", true, None);
        tray_menu.append_items(&[&toggle])?;

        let proxy = event_loop.create_proxy();
        MenuEvent::set_event_handler(Some(move |event| {
            if let Err(err) = proxy.send_event(UserEvent::MenuEvent(event)) {
                tracing::error!("Failed to proxy MenuEvent: {}", err);
            }
        }));

        let color: &Icon = Box::leak(Box::new(
            load_icon(include_bytes!("../assets/logo-color.png")).expect("valid icon"),
        ));
        let gray: &Icon = Box::leak(Box::new(
            load_icon(include_bytes!("../assets/logo-gray.png")).expect("valid icon"),
        ));
        let white: &Icon = Box::leak(Box::new(
            load_icon(include_bytes!("../assets/logo-white.png")).expect("valid icon"),
        ));

        let mut update = {
            let mut current_state = None;
            let enabled = enabled.clone();
            let toggle = toggle.clone();
            move |tray_icon: &mut TrayIcon| {
                let state = State {
                    enabled: *enabled.borrow(),
                    connection_state: *connection_state.borrow(),
                };
                if Some(state) != current_state {
                    current_state = Some(state);
                    toggle.set_text(if state.enabled { "Disable" } else { "Enable" });

                    tray_icon.set_title(Some(match state.connection_state {
                        ConnectionState::Connected { keep_awake: true } => "Keepawake requested",
                        ConnectionState::Connected { keep_awake: false } => "Connected",
                        ConnectionState::Disconnected => "Disconnected",
                    }));

                    // if let Err(err) = tray_icon.set_tooltip(Some(match state.connection_state {
                    //     ConnectionState::Connected { keep_awake: true } => "Keepawake requested",
                    //     ConnectionState::Connected { keep_awake: false } => "Connected",
                    //     ConnectionState::Disconnected => "Disconnected",
                    // })) {
                    //     tracing::warn!("Failed to update tooltip: {err}")
                    // }

                    if let Err(err) = tray_icon.set_icon(Some(
                        match (state.connection_state, state.enabled) {
                            (ConnectionState::Connected { keep_awake: true }, true) => color,
                            (ConnectionState::Connected { keep_awake: false }, true) => white,
                            _ => gray,
                        }
                        .clone(),
                    )) {
                        tracing::warn!("Failed to update icon: {err}")
                    }
                }
            }
        };

        let mut tray_icon = None;
        event_loop.run(move |event, _, control_flow| {
            *control_flow = ControlFlow::Wait;

            match event {
                Event::NewEvents(tao::event::StartCause::Init) => {
                    tray_icon = Some({
                        let mut tray_icon = TrayIconBuilder::new()
                            .with_menu(Box::new(tray_menu.clone()))
                            .build()
                            .unwrap();
                        update(&mut tray_icon);
                        tray_icon
                    });
                }
                Event::UserEvent(UserEvent::MenuEvent(event)) if event.id() == toggle.id() => {
                    enabled.send_modify(|enabled| {
                        *enabled = !*enabled;
                        if *enabled {
                            tracing::debug!("Enabled");
                        } else {
                            tracing::debug!("Disabled");
                        }
                    });
                }
                Event::UserEvent(UserEvent::StateChange) => {
                    if let Some(tray_icon) = &mut tray_icon {
                        update(tray_icon);
                    }
                }
                Event::UserEvent(UserEvent::Exit) | Event::LoopDestroyed => {
                    tracing::debug!("Toggled");
                    tray_icon.take();
                }
                _ => {
                    tracing::trace!("Ignored event {event:?}")
                }
            }
        });
    }
}

// impl ApplicationHandler<UserEvent> for Application {
//     fn resumed(&mut self, _event_loop: &winit::event_loop::ActiveEventLoop) {}
//
//     fn window_event(
//         &mut self,
//         _event_loop: &winit::event_loop::ActiveEventLoop,
//         _window_id: winit::window::WindowId,
//         _event: winit::event::WindowEvent,
//     ) {
//     }
//
//     fn new_events(
//         &mut self,
//         _event_loop: &winit::event_loop::ActiveEventLoop,
//         cause: winit::event::StartCause,
//     ) {
//         // We create the icon once the event loop is actually running
//         // to prevent issues like https://github.com/tauri-apps/tray-icon/issues/90
//         if winit::event::StartCause::Init == cause {
//             #[cfg(not(target_os = "linux"))]
//             {
//                 self.tray_icon = Some(self.new_tray_icon());
//             }
//
//             // We have to request a redraw here to have the icon actually show up.
//             // Winit only exposes a redraw method on the Window so we use core-foundation directly.
//             #[cfg(target_os = "macos")]
//             {
//                 use objc2_core_foundation::{CFRunLoopGetMain, CFRunLoopWakeUp};
//
//                 let rl = CFRunLoopGetMain().unwrap();
//                 CFRunLoopWakeUp(&rl);
//             }
//         }
//     }
//
//     fn user_event(&mut self, event_loop: &winit::event_loop::ActiveEventLoop, event: UserEvent) {
//         match event {
//             UserEvent::MenuEvent(MenuEvent { id }) if id == TOGGLE => {
//                 tracing::debug!("Toggled");
//                 self.enabled.send_modify(|enabled| {
//                     *enabled = !*enabled;
//                 });
//             }
//             UserEvent::MenuEvent(_) => {
//                 tracing::warn!("Unhandled menu event");
//             }
//             UserEvent::StateChange(state) => {
//                 if state != self.state {
//                     self.state = state;
//                     tracing::debug!("State changed");
//                     let menu = self.new_tray_menu().unwrap();
//                     if let Some(tray_icon) = &mut self.tray_icon {
//                         tray_icon.set_menu(Some(Box::new(menu)));
//                     }
//                 }
//             }
//             UserEvent::Exit => {
//                 tracing::debug!("Exiting");
//                 event_loop.exit();
//             }
//         }
//     }
// }

fn load_icon(bytes: &[u8]) -> anyhow::Result<tray_icon::Icon> {
    let (icon_rgba, icon_width, icon_height) = {
        let image = image::load_from_memory(bytes)?.into_rgba8();
        let (width, height) = image.dimensions();
        let rgba = image.into_raw();
        (rgba, width, height)
    };
    Ok(tray_icon::Icon::from_rgba(
        icon_rgba,
        icon_width,
        icon_height,
    )?)
}
