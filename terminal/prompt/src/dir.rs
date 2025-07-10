use std::{
    ffi::OsStr,
    num::NonZeroUsize,
    ops::ControlFlow,
    os::unix::ffi::OsStrExt,
    path::{MAIN_SEPARATOR, Path},
};

use git2::Repository;

use crate::{color, var_lossy};

const MAX_COMPONENTS: NonZeroUsize = NonZeroUsize::new(3).unwrap();

const MAIN_SEPARATOR_BYTE: u8 = MAIN_SEPARATOR as u8;

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
    let last_component_start = match find_nth_last_component_start(&mut iter, 0) {
        Some(last_component_start) => last_component_start,
        None => return (None, OsStr::from_bytes(bytes)),
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

fn fmt_dir<P: AsRef<Path>>(path: P) -> String {
    let (previous_components, final_component) =
        last_n_path_components(path.as_ref(), MAX_COMPONENTS);
    let mut s = " ".to_string();
    if let Some(previous_components) = previous_components {
        s += color::CYAN;
        s += previous_components.to_str().expect("UTF8");
    }
    s + color::CYAN_BOLD + final_component.to_str().expect("UTF8") + color::RESET
}

pub fn directory() -> (String, Option<Repository>) {
    let cwd = std::env::current_dir().expect("Can get current dir");

    if cwd == Path::new("/") {
        return (fmt_dir("/"), None);
    }

    match Repository::discover(&cwd) {
        Ok(repo) => {
            let git_root = repo.workdir().unwrap_or(&cwd);

            let rel_to_git_root = cwd
                .strip_prefix(
                    git_root
                        .parent()
                        .expect("Every git repository has a parent"),
                )
                .expect("cwd is (a subdir of) git_root");

            (fmt_dir(rel_to_git_root), Some(repo))
        }
        Err(_) => {
            let rel_to_home = cwd
                .strip_prefix(var_lossy("HOME").expect("$HOME is set"))
                .ok();

            let dir = match rel_to_home {
                Some(rel_to_home) => Path::new("~").join(rel_to_home),
                None => cwd,
            };

            (fmt_dir(dir), None)
        }
    }
}
