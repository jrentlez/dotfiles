use std::str::FromStr;

#[derive(Debug, Default, Clone, Copy)]
pub enum Shell {
    Bash,
    #[default]
    Zsh,
}
impl FromStr for Shell {
    type Err = ();

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "bash" | "Bash" => Ok(Shell::Bash),
            "zsh" | "Zsh" => Ok(Shell::Zsh),
            _ => Err(()),
        }
    }
}

macro_rules! ansi_sequence {
    ($name:ident, $sequence:literal) => {
        impl Shell {
            // NOTE: See https://github.com/starship/starship/issues/110
            pub const fn $name(self) -> &'static [u8] {
                match self {
                    // Wrap whith \[ \]
                    Self::Bash => concat!("\u{5c}\u{5b}", $sequence, "\u{5c}\u{5d}"),
                    // Wrap whith %{ %}
                    Self::Zsh => concat!("\u{25}\u{7b}", $sequence, "\u{25}\u{7d}"),
                }
                .as_bytes()
            }
        }
    };
}

ansi_sequence!(reset, "\x1b[0m");
ansi_sequence!(red, "\x1b[31m");
ansi_sequence!(red_bold, "\x1b[1;31m");
ansi_sequence!(yellow_normal, "\x1b[0;33m");
ansi_sequence!(blue, "\x1b[34m");
ansi_sequence!(magenta, "\x1b[35m");
ansi_sequence!(fg_normal, "\x1b[0;39m");
ansi_sequence!(fg_bold, "\x1b[1;39m");
ansi_sequence!(fg_dim, "\x1b[2;39m");
