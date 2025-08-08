use std::{
    env::var_os,
    ffi::OsStr,
    fs::metadata,
    num::NonZeroUsize,
    ops::ControlFlow,
    os::{linux::fs::MetadataExt, unix::ffi::OsStrExt},
    path::{Component, MAIN_SEPARATOR, Path, PathBuf},
};

use git2::Repository;

use crate::{ansi::Shell, var_lossy};

const MAX_COMPONENTS: NonZeroUsize = NonZeroUsize::new(3).unwrap();
const MAIN_SEPARATOR_BYTE: u8 = MAIN_SEPARATOR as u8;

// NOTE: Mostly taken from GNU pwd (logical path)
// See https://github.com/MaiZure/coreutils-8.3/blob/master/src/pwd.c
fn current_directory() -> PathBuf {
    let wd = PathBuf::from(var_os("PWD").expect("Can get PWD environment variable"));
    let mut components = wd.components();
    assert_eq!(
        Some(Component::RootDir),
        components.next(),
        "PWD starts with root"
    );
    for component in components {
        assert_ne!(
            Component::CurDir,
            component,
            "PWD does not contain '.' components"
        );
    }
    let wd_ino = wd.metadata().expect("PWD is accessible").st_ino();
    let dot_ino = metadata(".").expect("'.' is accessible").st_ino();
    assert_eq!(wd_ino, dot_ino, "PWD is the same INODE as '.'");
    wd
}

fn trim_trailing_separator(bytes: &[u8]) -> ControlFlow<&[u8], &[u8]> {
    if bytes
        .last()
        .is_some_and(|byte| *byte == MAIN_SEPARATOR_BYTE)
    {
        if bytes.len() == 1 {
            return ControlFlow::Break(bytes);
        }

        ControlFlow::Continue(&bytes[..bytes.len() - 1])
    } else {
        ControlFlow::Continue(bytes)
    }
}

#[inline]
fn find_nth_last_component_start<'a, I>(iter: &mut I, n: usize) -> Option<usize>
where
    I: Iterator<Item = &'a u8> + DoubleEndedIterator + ExactSizeIterator,
{
    let mut remaining_components = n + 1;
    iter.enumerate()
        .rfind(|(_, byte)| {
            if **byte == MAIN_SEPARATOR_BYTE {
                remaining_components -= 1;
                remaining_components == 0
            } else {
                false
            }
        })
        .map(|(idx, _)| idx + 1)
}

/// BUG: If the path contains "//" this will return incorrect results
fn last_n_path_components(path: &Path, n: NonZeroUsize) -> (Option<&OsStr>, &OsStr) {
    let bytes = match trim_trailing_separator(path.as_os_str().as_bytes()) {
        ControlFlow::Continue(bytes) => bytes,
        ControlFlow::Break(bytes) => return (None, OsStr::from_bytes(bytes)),
    };

    let mut iter = bytes.iter();
    let Some(last_component_start) = find_nth_last_component_start(&mut iter, 0) else {
        return (None, OsStr::from_bytes(bytes));
    };

    let remaining_components = n.get() - 1;
    if remaining_components == 0 {
        return (None, OsStr::from_bytes(&bytes[last_component_start..]));
    }

    match find_nth_last_component_start(&mut iter, remaining_components - 1) {
        Some(nth_last_component_start) => (
            Some(OsStr::from_bytes(
                &bytes[nth_last_component_start..last_component_start],
            )),
            OsStr::from_bytes(&bytes[last_component_start..]),
        ),
        None => (
            Some(OsStr::from_bytes(&bytes[..last_component_start])),
            OsStr::from_bytes(&bytes[last_component_start..]),
        ),
    }
}

fn fmt_dir<P: AsRef<Path>>(path: P, shell: Shell) -> String {
    let (previous_components, final_component) =
        last_n_path_components(path.as_ref(), MAX_COMPONENTS);
    let previous_components = previous_components
        .map(|previous_components| previous_components.to_str().expect("UTF8"))
        .unwrap_or_default();
    shell.fg_normal().to_string()
        + previous_components
        + shell.fg_bold()
        + final_component.to_str().expect("UTF8")
        + shell.reset()
        + " "
}

pub fn directory(shell: Shell) -> (String, Option<Repository>) {
    let wd = current_directory();

    if wd == Path::new("/") {
        return (fmt_dir("/", shell), None);
    }

    match Repository::discover(&wd) {
        Ok(repo) => {
            let git_root = repo.workdir().unwrap_or(&wd);

            let rel_to_git_root = wd
                .strip_prefix(
                    git_root
                        .parent()
                        .expect("Every git repository has a parent"),
                )
                .expect("cwd is (a subdir of) git_root");

            (fmt_dir(rel_to_git_root, shell), Some(repo))
        }
        Err(_) => {
            let rel_to_home = wd
                .strip_prefix(var_lossy("HOME").expect("$HOME is set"))
                .ok();

            let dir = match rel_to_home {
                Some(rel_to_home) => Path::new("~").join(rel_to_home),
                None => wd,
            };

            (fmt_dir(dir, shell), None)
        }
    }
}
