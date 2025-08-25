use std::{env::var_os, io::Write, os::unix::ffi::OsStrExt};

use crate::{ansi::Shell, write_bytes};

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

fn is_root() -> bool {
    unsafe { libc::geteuid() }.eq(&0)
}

fn is_ssh() -> bool {
    var_os("SSH_CONNECTION").is_some()
}

fn prompt_character() -> &'static [u8] {
    if is_root() && is_ssh() {
        b"@#"
    } else if is_root() {
        b"#"
    } else if is_ssh() {
        b"@"
    } else {
        b"$"
    }
}

pub fn colored_prompt_character(
    writer: &mut impl Write,
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
        prompt_character()
    );
}
