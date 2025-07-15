use dir::directory;
use git::git;
use std::{
    env::{self, VarError},
    ffi::OsStr,
    str::FromStr,
};

use crate::ansi::Shell;

mod ansi;
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

fn userhost(shell: Shell) -> Option<String> {
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

fn venv(shell: Shell) -> Option<String> {
    let venv_prompt = var_lossy("VIRTUAL_ENV_PROMPT")?;
    Some(shell.fg_italic().to_string() + "(" + &venv_prompt + ") ")
}

fn status(last_status: u8, shell: Shell) -> Option<String> {
    if last_status != 0 {
        Some(shell.red().to_string() + &last_status.to_string() + " ")
    } else {
        None
    }
}

#[derive(Default)]
enum ToPrint {
    PreCmd,
    LastLine,
    #[default]
    All,
}
impl ToPrint {
    fn pre_cmd(shell: Shell) -> String {
        let userhost = userhost(shell).unwrap_or_default();
        let (dir, repo) = directory(shell);
        let git_status = repo.map(|repo| git(&repo, shell)).unwrap_or_default();
        let python_venv = venv(shell).unwrap_or_default();
        format!(
            "\n{}{userhost}{dir}{git_status}{python_venv}",
            shell.fg_normal()
        )
    }

    fn last_line(job_count: usize, last_status: u8, shell: Shell) -> String {
        let job_symbol = if job_count > 0 { "✦ " } else { "" };
        let last_status_symbol = status(last_status, shell).unwrap_or_default();
        format!(
            "{}{job_symbol}{last_status_symbol}{}",
            shell.fg_normal(),
            shell.fg_normal()
        )
    }
}
impl FromStr for ToPrint {
    type Err = ();

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "precmd" => Ok(ToPrint::PreCmd),
            "lastline" => Ok(ToPrint::LastLine),
            _ => Err(()),
        }
    }
}

fn main() {
    let mut job_count = 0;
    let mut last_status = 0;
    let mut to_print = ToPrint::default();
    let mut shell = Shell::default();
    for arg in env::args().skip(1) {
        match arg.parse::<ToPrint>() {
            Ok(tp) => {
                to_print = tp;
                continue;
            }
            Err(()) => match arg.split_once('=') {
                Some(("jobs", jc)) => {
                    job_count = jc
                        .parse::<usize>()
                        .expect("Amount of running jobs fits into usize");
                }
                Some(("laststatus", ls)) => {
                    last_status = ls.parse::<u8>().expect("Last exit code fits into u8");
                }
                Some(("shell", sh)) => {
                    shell = sh
                        .parse::<Shell>()
                        .expect("Only bash and zsh are supported");
                }
                Some(_) | None => continue,
            },
        }
    }

    match to_print {
        ToPrint::PreCmd => {
            print!("{}", ToPrint::pre_cmd(shell));
        }
        ToPrint::LastLine => {
            print!("{}", ToPrint::last_line(job_count, last_status, shell));
        }
        ToPrint::All => {
            print!(
                "{}\n{}",
                ToPrint::pre_cmd(shell),
                ToPrint::last_line(job_count, last_status, shell)
            );
        }
    }
}
