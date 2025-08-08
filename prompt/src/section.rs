use std::{ffi::OsStr, io::Write};

use crate::{
    ansi::Shell,
    dir::directory,
    git::git,
    misc::{colored_prompt_suffix, userhost, venv},
    write_bytes,
};

#[derive(Default, Debug, Clone, Copy)]
pub enum Section {
    PreCmd,
    LastLine,
    #[default]
    All,
}
impl Section {
    fn pre_cmd(writer: &mut impl Write, shell: Shell) {
        write_bytes!(writer, b"\n", shell.fg_normal());
        userhost(writer, shell);
        if let Some(repo) = directory(writer, shell) {
            git(writer, &repo, shell);
        }
        venv(writer, shell);
    }

    fn last_line(
        writer: &mut impl Write,
        job_count: usize,
        last_status: u8,
        prompt_suffix: &OsStr,
        shell: Shell,
    ) {
        colored_prompt_suffix(writer, prompt_suffix, job_count, last_status, shell);
        write_bytes!(writer, shell.fg_normal(), b" ");
    }

    pub fn write(
        self,
        mut writer: impl Write,
        shell: Shell,
        job_count: usize,
        last_status: u8,
        prompt_suffix: &OsStr,
    ) {
        match self {
            Self::PreCmd => Self::pre_cmd(&mut writer, shell),
            Self::LastLine => {
                Self::last_line(&mut writer, job_count, last_status, prompt_suffix, shell);
            }
            Self::All => {
                Self::pre_cmd(&mut writer, shell);
                write_bytes!(writer, b"\n");
                Self::last_line(&mut writer, job_count, last_status, prompt_suffix, shell);
            }
        }
    }
}
impl TryFrom<&OsStr> for Section {
    type Error = ();

    fn try_from(s: &OsStr) -> Result<Self, Self::Error> {
        if s == "precmd" {
            Ok(Section::PreCmd)
        } else if s == "lastline" {
            Ok(Section::LastLine)
        } else {
            Err(())
        }
    }
}
