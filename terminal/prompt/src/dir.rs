use std::path::{Path, PathBuf};

use git2::Repository;

use crate::{color, var_lossy};

fn fmt_dir<P: AsRef<Path>>(path: P) -> String {
    const CAP: usize = 3;
    let path = path.as_ref();
    let (elems, idx) = path.iter().fold(
        ([std::ffi::OsStr::new(""); CAP], 0),
        |(mut elems, idx), sec| {
            elems[idx] = sec;
            (elems, (idx + 1) % CAP)
        },
    );

    let truncated = (idx..(idx + CAP))
        .map(|idx| elems[idx % CAP])
        .collect::<PathBuf>();

    color::CYAN_BOLD.to_string() + " " + truncated.to_str().expect("UTF8") + color::RESET
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
