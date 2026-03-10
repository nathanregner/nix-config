// Catppuccin Mocha colors
pub const BLACK_4: u32 = 0x585b70;
pub const FG: u32 = 0xcdd6f4;
pub const RED: u32 = 0xf38ba8;

pub fn ansi_rgb(hex: u32, text: &str) -> String {
    let r = (hex >> 16) & 0xFF;
    let g = (hex >> 8) & 0xFF;
    let b = hex & 0xFF;
    format!("\x1b[38;2;{r};{g};{b}m{text}\x1b[0m")
}

pub fn hex_rgb(hex: u32) -> String {
    format!("#{:06x}", hex)
}
