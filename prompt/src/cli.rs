use std::{
    ffi::{OsStr, OsString},
    os::unix::ffi::OsStrExt,
};

use crate::{ansi::Shell, section::Section};

#[derive(Debug, Default)]
struct ArgsBuilder {
    section: Option<Section>,
    job_count: Option<usize>,
    last_status: Option<u8>,
    shell: Option<Shell>,
    prompt_suffix: Option<OsString>,
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
            prompt_suffix: prompt_suffix.unwrap_or_else(|| OsString::from("$")),
        }
    }
}

#[derive(Debug)]
pub struct Args {
    section: Section,
    job_count: usize,
    last_status: u8,
    shell: Shell,
    prompt_suffix: OsString,
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

    pub fn prompt_suffix(&self) -> &OsStr {
        &self.prompt_suffix
    }
}
impl FromIterator<OsString> for Args {
    fn from_iter<T: IntoIterator<Item = OsString>>(iter: T) -> Self {
        iter.into_iter()
            .fold(ArgsBuilder::default(), |mut builder, arg| {
                let arg_bytes = arg.as_bytes();
                let key_value = arg_bytes.iter().position(|b| *b == b'=').map(|idx| {
                    let (key, mut value) = arg_bytes.split_at(idx);
                    let equals = value.split_off_first();
                    assert_eq!(equals, Some(&b'='));
                    (OsStr::from_bytes(key), OsStr::from_bytes(value))
                });
                let Some((key, value)) = key_value else {
                    return builder;
                };
                if key == "print" {
                    builder.section =
                        Some(Section::try_from(value).expect("Unsupported print value"));
                } else if key == "jobs" {
                    let value = value.to_str().expect("UTF-8");
                    builder.job_count = Some(
                        value
                            .parse()
                            .expect("Amount of running jobs fits into usize"),
                    );
                } else if key == "laststatus" {
                    let value = value.to_str().expect("UTF-8");
                    builder.last_status = Some(value.parse().expect("Last exit code fits into u8"));
                } else if key == "shell" {
                    let value = value.to_str().expect("UTF-8");
                    builder.shell = Some(value.parse().expect("Only bash and zsh are supported"));
                } else if key == "prompt_character" {
                    builder.prompt_suffix = Some(value.to_os_string());
                }
                builder
            })
            .finish()
    }
}
