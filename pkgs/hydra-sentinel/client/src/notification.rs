use crate::ConnectionState;
use anyhow::Result;
use tokio::sync::watch;
use tray_icon::{
    menu::{Menu, MenuEvent, MenuItem, PredefinedMenuItem},
    Icon, TrayIcon, TrayIconBuilder,
};

const ENABLE: &str = "Enable Keepalive";
const DISABLE: &str = "Disable Keepalive";

pub struct NotificationManager {
    enabled_rx: watch::Receiver<bool>,
    connection_state_rx: watch::Receiver<ConnectionState>,
    tray_icon: TrayIcon,
    toggle_menu_item: MenuItem,
}

impl NotificationManager {
    pub fn new(
        connection_state_rx: watch::Receiver<ConnectionState>,
    ) -> Result<(watch::Receiver<bool>, Self)> {
        let (enabled_tx, enabled_rx) = watch::channel(true);

        let menu = Menu::new();
        let toggle_menu_item = MenuItem::new("Disable Keepalive", true, None);
        let quit = MenuItem::new("Quit", true, None);

        menu.append_items(&[&toggle_menu_item, &PredefinedMenuItem::separator(), &quit])?;

        let icon = Self::create_icon_for_state(&connection_state_rx.borrow())?;

        let tray_icon = TrayIconBuilder::new()
            .with_menu(Box::new(menu))
            .with_tooltip("Hydra Sentinel Client - Disconnected")
            .with_icon(icon)
            .build()?;

        // Handle menu events
        // let toggle_menu_item = Arc::clone(&self.toggle_menu_item);
        MenuEvent::set_event_handler(Some(move |event: MenuEvent| {
            match event.id.0.as_str() {
                DISABLE | ENABLE => {
                    enabled_tx.send_modify(|enabled| {
                        *enabled = !*enabled;
                    });
                    let enabled = *enabled_tx.borrow();
                    tracing::info!(
                        "Keepalive manually {}",
                        if enabled { "disabled" } else { "enabled" }
                    );

                    // toggle_keepalive.set_text(new_text);

                    // Update menu item text
                    // if let Some(menu_item) = toggle_menu_item.lock().unwrap().as_ref() {
                    //     let _ = menu_item.set_text(new_text);
                    // }
                }
                "Quit" => {
                    // TODO
                    std::process::exit(0);
                }
                _ => {}
            }
        }));

        Ok((
            enabled_rx.clone(),
            Self {
                enabled_rx,
                connection_state_rx,
                tray_icon,
                toggle_menu_item,
            },
        ))
    }

    // blocks, spawn on separate thread?
    pub async fn spawn(mut self) -> Result<()> {
        loop {
            let enabled = self.enabled_rx.borrow();
            let connection_state = self.connection_state_rx.borrow();
            self.update_state(*enabled, *connection_state)?;
            drop((enabled, connection_state));
            tokio::select! {
                _ = self.enabled_rx.changed() => {},
                _ = self.connection_state_rx.changed() => {},
            };
        }
    }

    pub fn update_state(&self, enabled: bool, connection_state: ConnectionState) -> Result<()> {
        self.toggle_menu_item
            .set_text(if enabled { ENABLE } else { DISABLE });

        let icon = Self::create_icon_for_state(&connection_state)?;
        let tooltip = match connection_state {
            ConnectionState::Disconnected => "Hydra Sentinel Client - Disconnected",
            ConnectionState::Connected { keep_awake: false } => "Hydra Sentinel Client - Connected",
            ConnectionState::Connected { keep_awake: true } => {
                "Hydra Sentinel Client - Keep Awake Active"
            }
        };

        self.tray_icon.set_icon(Some(icon))?;
        self.tray_icon.set_tooltip(Some(tooltip))?;

        Ok(())
    }

    fn create_icon_for_state(state: &ConnectionState) -> Result<Icon> {
        // Create simple colored icons using image crate
        let (r, g, b) = match state {
            ConnectionState::Disconnected => (128, 128, 128), // Gray
            ConnectionState::Connected { keep_awake: false } => (0, 128, 255), // Blue
            ConnectionState::Connected { keep_awake: true } => (255, 165, 0), // Orange
        };

        let mut img_buffer = vec![0u8; 16 * 16 * 4]; // 16x16 RGBA

        for i in 0..16 * 16 {
            let offset = i * 4;
            img_buffer[offset] = r; // R
            img_buffer[offset + 1] = g; // G
            img_buffer[offset + 2] = b; // B
            img_buffer[offset + 3] = 255; // A
        }

        Icon::from_rgba(img_buffer, 16, 16).map_err(Into::into)
    }
}
