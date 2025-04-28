use dir::directory;
use git::git;
use std::{
    env::{self, VarError},
    ffi::OsStr,
};

mod color;
mod dir;
mod git;

#[inline]
fn is_root() -> bool {
    nix::unistd::geteuid() == nix::unistd::ROOT
}

fn var_lossy<K: AsRef<OsStr>>(key: K) -> Option<String> {
    env::var(key)
        .or_else(|err| match err {
            VarError::NotPresent => Err(()),
            VarError::NotUnicode(s) => Ok(s.to_string_lossy().to_string()),
        })
        .ok()
}

fn userhost() -> Option<String> {
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

    if !show_username {
        None
    } else if is_root {
        Some(color::RED.to_string() + " " + &userhost)
    } else {
        Some(" ".to_string() + color::YELLOW + &userhost)
    }
}

fn venv() -> Option<String> {
    let venv_prompt = var_lossy("VIRTUAL_ENV_PROMPT")?;
    Some(color::GREEN.to_string() + " (" + &venv_prompt + ")")
}

fn status(last_status: u8) -> Option<String> {
    if last_status != 0 {
        Some(color::RED.to_string() + " " + &last_status.to_string())
    } else {
        None
    }
}

fn main() {
    let mut args = env::args();
    let _ = args.next();
    let job_count = args
        .next()
        .and_then(|jc| jc.parse::<usize>().ok())
        .unwrap_or_default();
    let last_status = args
        .next()
        .and_then(|ls| ls.parse::<u8>().ok())
        .unwrap_or_default();

    let userhost = userhost().unwrap_or_default();
    let (dir, repo) = directory();
    let gstat = repo.map(|repo| git(&repo)).unwrap_or_default();
    let pyvenv = venv().unwrap_or_default();
    let stat = status(last_status).unwrap_or_default();
    println!(
        "\n{}╭{userhost}{dir}{gstat}{pyvenv}\n{}╰{}{stat} ",
        color::GREEN,
        color::GREEN,
        if job_count > 0 {
            color::BLUE.to_string() + " ✦"
        } else {
            "".to_string()
        }
    );
}
