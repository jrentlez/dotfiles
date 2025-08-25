use std::{
    env::{current_dir, var_os},
    fs::metadata,
    io::Write,
    os::{linux::fs::MetadataExt, unix::ffi::OsStrExt},
    path::{Component, MAIN_SEPARATOR, Path, PathBuf},
};

use git2::Repository;

use crate::{ansi::Shell, write_bytes};

const MAIN_SEPARATOR_BYTE: u8 = MAIN_SEPARATOR as u8;

// NOTE: Mostly taken from GNU pwd (logical path)
// See https://github.com/MaiZure/coreutils-8.3/blob/master/src/pwd.c
fn current_logical_directory() -> Option<PathBuf> {
    let wd = PathBuf::from(var_os("PWD")?);
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
    Some(wd)
}

fn current_physical_directory() -> PathBuf {
    current_dir().expect("Can get current directory")
}

#[inline]
fn trim_trailing_separator(bytes: &mut &[u8]) {
    if bytes
        .last()
        .is_some_and(|byte| *byte == MAIN_SEPARATOR_BYTE)
    {
        bytes.split_off_last().expect("Bytes is not empty");
    }
}

fn path_split_last(path: &Path) -> (Option<&[u8]>, &[u8]) {
    let mut bytes = path.as_os_str().as_bytes();
    if bytes == [MAIN_SEPARATOR_BYTE] {
        return (None, bytes);
    }

    trim_trailing_separator(&mut bytes);
    let Some(last_component_start) = bytes.iter().rposition(|b| *b == MAIN_SEPARATOR_BYTE) else {
        return (None, bytes);
    };

    let (prev, last) = bytes.split_at(last_component_start + 1);
    (Some(prev), last)
}

fn replace_home_with_tilde(path: &Path, home: &Path) -> Option<PathBuf> {
    match path.strip_prefix(home) {
        Ok(p) => Some(PathBuf::from("~").join(p)),
        Err(_) => None,
    }
}

fn write_current_dir(writer: &mut impl Write, shell: Shell, relative_to: Option<&Path>) {
    let home = PathBuf::from(var_os("HOME").expect("$HOME is set"));
    let physical = current_physical_directory();
    match current_logical_directory() {
        Some(logical) if logical != physical => {
            let logical_tilded = replace_home_with_tilde(&logical, &home).unwrap_or(logical);
            let (previous_components, final_component) = path_split_last(&logical_tilded);
            let physical_tilded = replace_home_with_tilde(&physical, &home).unwrap_or(physical);
            write_bytes!(
                writer,
                shell.fg_normal(),
                previous_components.unwrap_or_default(),
                shell.fg_bold(),
                final_component,
                shell.reset(),
                shell.fg_dim(),
                b"(",
                physical_tilded.as_os_str().as_bytes(),
                b")"
            );
        }
        None | Some(_) => {
            let stripped = relative_to
                .and_then(|relative_to| physical.strip_prefix(relative_to).ok())
                .unwrap_or(&physical);
            let tilded = replace_home_with_tilde(stripped, &home);
            let (previous_components, final_component) = match &tilded {
                Some(tilded) => path_split_last(tilded),
                None => path_split_last(stripped),
            };
            write_bytes!(
                writer,
                shell.fg_normal(),
                previous_components.unwrap_or_default(),
                shell.fg_bold(),
                final_component
            );
        }
    }
    write_bytes!(writer, shell.reset(), b" ");
}

pub fn directory(writer: &mut impl Write, shell: Shell) -> Option<Repository> {
    let cwd = current_physical_directory();

    match Repository::discover(&cwd) {
        Ok(repo) => {
            let git_root_parent = repo.workdir().unwrap_or(&cwd).parent();
            write_current_dir(writer, shell, git_root_parent);
            Some(repo)
        }
        Err(_) => {
            write_current_dir(writer, shell, None);
            None
        }
    }
}
