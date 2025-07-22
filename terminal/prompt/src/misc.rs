use crate::{ansi::Shell, var_lossy};

#[inline]
fn is_root() -> bool {
    nix::unistd::geteuid() == nix::unistd::ROOT
}

pub fn userhost(shell: Shell) -> Option<String> {
    let mut userhost = var_lossy("USER").expect("$USER is present");

    let is_root = is_root();
    let show_username = is_root
        || var_lossy("LOGNAME").is_some_and(|logname| logname != userhost)
        || ["SSH_CONNECTION", "SSH_CLIENT", "SSH_TTY"]
            .iter()
            .any(|var| var_lossy(var).is_some());
    if var_lossy("SSH_CONNECTION").is_some() {
        let host = nix::unistd::gethostname().expect("Can get hostname");
        userhost.push('@');
        userhost.push_str(&host.to_string_lossy());
    }
    userhost.push(' ');

    if !show_username {
        None
    } else if is_root {
        Some(shell.red().to_string() + &userhost)
    } else {
        Some(shell.fg_italic().to_string() + &userhost)
    }
}

pub fn venv(shell: Shell) -> Option<String> {
    let venv_prompt = var_lossy("VIRTUAL_ENV_PROMPT")?;
    Some(shell.fg_italic().to_string() + "(" + &venv_prompt + ") ")
}

pub fn colored_prompt_suffix(
    suffix: &str,
    job_count: usize,
    last_status: u8,
    shell: Shell,
) -> String {
    if job_count > 0 && last_status > 0 {
        shell.magenta()
    } else if job_count > 0 {
        shell.blue()
    } else if last_status > 0 {
        shell.red()
    } else {
        shell.fg_normal()
    }
    .to_string()
        + suffix
}
