use std::{
    env::{VarError, args_os, var},
    ffi::OsStr,
};

use cli::Args;

mod ansi;
mod cli;
mod dir;
mod git;
mod misc;
mod section;

fn var_lossy<K: AsRef<OsStr>>(key: K) -> Option<String> {
    var(key)
        .or_else(|err| match err {
            VarError::NotPresent => Err(()),
            VarError::NotUnicode(s) => Ok(s.to_string_lossy().to_string()),
        })
        .ok()
}

fn main() {
    let args = args_os().skip(1).collect::<Args>();
    args.section().print(
        args.shell(),
        args.job_count(),
        args.last_status(),
        args.prompt_suffix(),
    );
}
