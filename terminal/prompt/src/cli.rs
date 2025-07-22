use std::ffi::OsString;

use crate::{ansi::Shell, section::Section};

#[derive(Debug, Default)]
struct ArgsBuilder {
    section: Option<Section>,
    job_count: Option<usize>,
    last_status: Option<u8>,
    shell: Option<Shell>,
    prompt_suffix: Option<String>,
}
impl ArgsBuilder {
    fn finish(self) -> Args {
        let ArgsBuilder {
            section,
            job_count,
            last_status,
            shell,
            prompt_suffix,
        } = self;
        Args {
            section: section.unwrap_or_default(),
            job_count: job_count.unwrap_or_default(),
            last_status: last_status.unwrap_or_default(),
            shell: shell.unwrap_or_default(),
            prompt_suffix: prompt_suffix.unwrap_or_else(|| '$'.to_string()),
        }
    }
}

#[derive(Debug)]
pub struct Args {
    section: Section,
    job_count: usize,
    last_status: u8,
    shell: Shell,
    prompt_suffix: String,
}

impl Args {
    pub fn section(&self) -> Section {
        self.section
    }

    pub fn job_count(&self) -> usize {
        self.job_count
    }

    pub fn last_status(&self) -> u8 {
        self.last_status
    }

    pub fn shell(&self) -> Shell {
        self.shell
    }

    pub fn prompt_suffix(&self) -> &str {
        &self.prompt_suffix
    }
}
impl FromIterator<OsString> for Args {
    fn from_iter<T: IntoIterator<Item = OsString>>(iter: T) -> Self {
        iter.into_iter()
            .fold(ArgsBuilder::default(), |mut builder, s| {
                let s = s.to_string_lossy();
                match s.split_once('=') {
                    Some(("print", tp)) => {
                        builder.section = Some(tp.parse().expect("Unsupported print value"));
                    }
                    Some(("jobs", jc)) => {
                        builder.job_count =
                            Some(jc.parse().expect("Amount of running jobs fits into usize"));
                    }
                    Some(("laststatus", ls)) => {
                        builder.last_status =
                            Some(ls.parse().expect("Last exit code fits into u8"));
                    }
                    Some(("shell", sh)) => {
                        builder.shell = Some(sh.parse().expect("Only bash and zsh are supported"));
                    }
                    Some(("prompt_character", suffix)) => {
                        builder.prompt_suffix = Some(suffix.to_string());
                    }
                    Some(_) | None => {}
                }
                builder
            })
            .finish()
    }
}
