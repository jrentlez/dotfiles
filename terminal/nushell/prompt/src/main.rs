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

fn status() -> Option<String> {
    let status = var_lossy("LAST_EXIT_CODE")?;
    if status != "0" {
        Some(color::RED.to_string() + " " + &status)
    } else {
        None
    }
}

fn main() {
    let job_count = env::args()
        .nth(1)
        .and_then(|jc| jc.parse::<usize>().ok())
        .unwrap_or_default();
    let userhost = userhost().unwrap_or_default();
    let (dir, repo) = directory();
    let gstat = match repo {
        Some(repo) => git(&repo),
        None => "".to_string(),
    };
    let pyvenv = venv().unwrap_or_default();
    let stat = status().unwrap_or_default();
    println!(
        "\n╭{userhost}{dir}{gstat}{pyvenv}\n{}╰{}{stat} ",
        color::GREEN,
        if job_count > 0 {
            color::BLUE.to_string() + " ✦"
        } else {
            "".to_string()
        }
    );
}
