use dir::directory;
use git::git;
use std::{
    env::{self, VarError},
    ffi::OsStr,
    str::FromStr,
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

#[derive(Default)]
enum ToPrint {
    PreCmd,
    LastLine,
    #[default]
    All,
}
impl ToPrint {
    fn pre_cmd() -> String {
        let userhost = userhost().unwrap_or_default();
        let (dir, repo) = directory();
        let gstat = repo.map(|repo| git(&repo)).unwrap_or_default();
        let pyvenv = venv().unwrap_or_default();
        format!("\n{}╭{userhost}{dir}{gstat}{pyvenv}", color::GREEN)
    }

    fn last_line(job_count: usize, last_status: u8) -> String {
        let stat = status(last_status).unwrap_or_default();
        format!(
            "{}╰{}{stat} ",
            color::GREEN,
            if job_count > 0 {
                color::BLUE.to_string() + " ✦"
            } else {
                "".to_string()
            }
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
                Some(_) | None => continue,
            },
        }
    }

    match to_print {
        ToPrint::PreCmd => {
            print!("{}", ToPrint::pre_cmd());
        }
        ToPrint::LastLine => {
            print!("{}", ToPrint::last_line(job_count, last_status));
        }
        ToPrint::All => {
            print!(
                "{}\n{}",
                ToPrint::pre_cmd(),
                ToPrint::last_line(job_count, last_status)
            );
        }
    }
}
