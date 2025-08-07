use std::str::FromStr;

use crate::{
    ansi::Shell,
    dir::directory,
    git::git,
    misc::{colored_prompt_suffix, userhost, venv},
};

#[derive(Default, Debug, Clone, Copy)]
pub enum Section {
    PreCmd,
    LastLine,
    #[default]
    All,
}
impl Section {
    fn pre_cmd(shell: Shell) -> String {
        let userhost = userhost(shell).unwrap_or_default();
        let (dir, repo) = directory(shell);
        let git_status = repo.map(|repo| git(&repo, shell)).unwrap_or_default();
        let python_venv = venv(shell).unwrap_or_default();

        "\n".to_string() + shell.fg_normal() + &userhost + &dir + &git_status + &python_venv
    }

    fn last_line(job_count: usize, last_status: u8, prompt_suffix: &str, shell: Shell) -> String {
        colored_prompt_suffix(prompt_suffix, job_count, last_status, shell)
            + shell.fg_normal()
            + " "
    }

    pub fn print(self, shell: Shell, job_count: usize, last_status: u8, prompt_suffix: &str) {
        match self {
            Self::PreCmd => {
                print!("{}", Self::pre_cmd(shell));
            }
            Self::LastLine => {
                print!(
                    "{}",
                    Self::last_line(job_count, last_status, prompt_suffix, shell)
                );
            }
            Self::All => {
                print!(
                    "{}\n{}",
                    Self::pre_cmd(shell),
                    Self::last_line(job_count, last_status, prompt_suffix, shell)
                );
            }
        }
    }
}
impl FromStr for Section {
    type Err = ();

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "precmd" => Ok(Section::PreCmd),
            "lastline" => Ok(Section::LastLine),
            _ => Err(()),
        }
    }
}
