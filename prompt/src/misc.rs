use std::{env::var_os, ffi::OsStr, io::Write, os::unix::ffi::OsStrExt};

use crate::{ansi::Shell, write_bytes};

#[inline]
fn is_root() -> bool {
    nix::unistd::geteuid() == nix::unistd::ROOT
}

pub fn userhost(writer: &mut impl Write, shell: Shell) {
    let userhost = var_os("USER").expect("$USER is present");

    let show_username = is_root()
        || var_os("LOGNAME").is_some_and(|logname| logname != userhost)
        || ["SSH_CONNECTION", "SSH_CLIENT", "SSH_TTY"]
            .iter()
            .any(|var| var_os(var).is_some());
    if !show_username {
        return;
    }

    write_bytes!(
        writer,
        if is_root() {
            shell.red()
        } else {
            shell.fg_italic()
        },
        userhost.as_bytes()
    );

    if var_os("SSH_CONNECTION").is_some() {
        let host = nix::unistd::gethostname().expect("Can get hostname");
        write_bytes!(writer, b"@", host.as_bytes());
    }
    write_bytes!(writer, b" ");
}

pub fn venv(writer: &mut impl Write, shell: Shell) {
    let Some(venv_prompt) = var_os("VIRTUAL_ENV_PROMPT") else {
        return;
    };
    write_bytes!(
        writer,
        shell.fg_italic(),
        b"(",
        venv_prompt.as_bytes(),
        b")"
    );
}

pub fn colored_prompt_suffix(
    writer: &mut impl Write,
    suffix: &OsStr,
    job_count: usize,
    last_status: u8,
    shell: Shell,
) {
    write_bytes!(
        writer,
        if job_count > 0 && last_status > 0 {
            shell.magenta()
        } else if job_count > 0 {
            shell.blue()
        } else if last_status > 0 {
            shell.red()
        } else {
            shell.fg_normal()
        },
        suffix.as_bytes()
    );
}
