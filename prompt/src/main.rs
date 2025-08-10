use std::{
    env::args_os,
    io::{BufWriter, stdout},
};

use cli::Args;

mod ansi;
mod cli;
mod dir;
mod git;
mod misc;
mod section;

macro_rules! write_bytes {
    ($wr:ident$(, $s: expr)*) => {
        $($wr.write_all($s).expect("Can write");)*
    };
}
pub(crate) use write_bytes;

fn strip_prefix_bytes<'a>(mut slice: &'a [u8], prefix: &[u8]) -> Option<&'a [u8]> {
    let removed = slice.split_off(..prefix.len());
    if removed.is_some_and(|removed| removed == prefix) {
        Some(slice)
    } else {
        None
    }
}

fn split_bytes_once(bytes: &[u8], delimiter: u8) -> Option<(&[u8], &[u8])> {
    bytes
        .iter()
        .position(|b| *b == delimiter)
        .map(|delimiter_idx| {
            let (before, after_with_delimiter) = bytes.split_at(delimiter_idx);
            let (delim, after) = after_with_delimiter
                .split_first()
                .expect("Must contain delimiter");
            assert_eq!(delimiter, *delim, "Must split delimiter");
            (before, after)
        })
}

fn main() {
    let args = args_os().skip(1).collect::<Args>();
    args.section().write(
        BufWriter::new(stdout()),
        args.shell(),
        args.job_count(),
        args.last_status(),
        args.prompt_suffix(),
    );
}
