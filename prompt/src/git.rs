use std::io::Write;

use git2::{Branch, BranchType, Commit, ErrorCode, Repository, StatusOptions};

use crate::{ansi::Shell, strip_prefix_bytes, write_bytes};

enum Head<'repo> {
    Unborn,
    Branch(Branch<'repo>),
    Commit(Commit<'repo>),
}

fn read_head(repo: &Repository) -> Head<'_> {
    match repo.head() {
        Ok(head) => {
            let short = head.shorthand().expect("HEAD has shorthand");
            if short == "HEAD" {
                let commit = head
                    .peel_to_commit()
                    .expect("Detached head points to commit");
                Head::Commit(commit)
            } else {
                let branch = repo
                    .find_branch(short, BranchType::Local)
                    .expect("Branch is HEAD");
                Head::Branch(branch)
            }
        }
        Err(err) => match err.code() {
            ErrorCode::UnbornBranch => Head::Unborn,
            code => unreachable!("{code:?}: {err}"),
        },
    }
}

fn git_status(writer: &mut impl Write, repo: &Repository) {
    let mut opts = StatusOptions::new();
    opts.include_untracked(true)
        .recurse_untracked_dirs(true)
        .renames_index_to_workdir(true)
        .renames_from_rewrites(true)
        .renames_head_to_index(true);

    let stats = match repo.statuses(Some(&mut opts)) {
        Ok(stats) => stats,
        Err(error) => match error.code() {
            git2::ErrorCode::BareRepo => return,
            code => {
                panic!("{code:?}: {error}")
            }
        },
    };
    let Some(stat) = stats
        .into_iter()
        .map(|stat| stat.status())
        .reduce(|a, b| a | b)
    else {
        return;
    };

    let mut status = vec![];
    if stat.is_conflicted() {
        status.push(b'C');
    }
    if stat.is_wt_new() {
        status.push(b'n');
    }
    if stat.is_index_new() {
        status.push(b'N');
    }
    if stat.is_wt_modified() {
        status.push(b'm');
    }
    if stat.is_index_modified() {
        status.push(b'M');
    }
    if stat.is_wt_typechange() {
        status.push(b't');
    }
    if stat.is_index_typechange() {
        status.push(b'T');
    }
    if stat.is_wt_renamed() {
        status.push(b'r');
    }
    if stat.is_index_renamed() {
        status.push(b'R');
    }
    if stat.is_wt_deleted() {
        status.push(b'd');
    }
    if stat.is_index_deleted() {
        status.push(b'D');
    }
    write_bytes!(writer, &status);
}

fn has_stash(repo: &Repository) -> bool {
    match repo.reflog("refs/stash") {
        Ok(reflog) => !reflog.is_empty(),
        Err(_) => false,
    }
}

struct Upstream<'b> {
    branch: Branch<'b>,
    ahead_behind: &'static str,
}

fn read_upstream<'b>(repo: &Repository, local: &Branch<'b>) -> Option<Upstream<'b>> {
    let upstream = local.upstream().ok()?;
    let local_id = local.get().target().expect("HEAD points to a reference");
    let upstream_id = upstream
        .get()
        .target()
        .expect("upstream points to a reference");

    let (ahead, behind) = repo
        .graph_ahead_behind(local_id, upstream_id)
        .expect("Has ahead begind count");

    let ahead_behind = if ahead > 0 && behind > 0 {
        "AB"
    } else if ahead > 0 {
        "A"
    } else if behind > 0 {
        "B"
    } else {
        ""
    };
    Some(Upstream {
        branch: upstream,
        ahead_behind,
    })
}

pub fn git(writer: &mut impl Write, repo: &Repository, shell: Shell) {
    write_bytes!(writer, shell.fg_dim());

    let ahead_behind = match read_head(repo) {
        Head::Unborn => {
            let head = repo.find_reference("HEAD").expect("Can read head file");
            let head_name = head.symbolic_target_bytes().expect("Is symbolic");
            let head_name_stripped = strip_prefix_bytes(head_name, b"refs/heads/")
                .expect("target starts with refs/heads/");
            write_bytes!(writer, head_name_stripped);
            None
        }
        Head::Commit(commit) => {
            let id = commit
                .into_object()
                .short_id()
                .expect("Commit hash short id");
            write_bytes!(writer, &id);
            None
        }
        Head::Branch(local) => {
            let local_name = local.name_bytes().expect("Branch has name");
            match read_upstream(repo, &local) {
                Some(Upstream {
                    branch: upstream,
                    ahead_behind,
                }) => {
                    let remote_without_slash = repo
                        .branch_remote_name(upstream.get().name().expect("UTF8"))
                        .expect("Already verified existing upstream");
                    let upstream_name_with_remote = upstream.name_bytes().expect("Branch has name");
                    let mut upstream_branch_name =
                        strip_prefix_bytes(upstream_name_with_remote, &remote_without_slash)
                            .expect("Upstream starts with remote");
                    let slash = upstream_branch_name.split_off_first();
                    assert_eq!(slash, Some(&b'/'));

                    if local_name == upstream_branch_name {
                        write_bytes!(writer, upstream_branch_name);
                    } else {
                        write_bytes!(writer, local_name, b":", upstream_branch_name);
                    }
                    Some(ahead_behind)
                }
                None => {
                    write_bytes!(writer, local_name);
                    None
                }
            }
        }
    };

    write_bytes!(writer, shell.yellow_normal());
    git_status(writer, repo);
    write_bytes!(
        writer,
        shell.fg_normal(),
        ahead_behind.unwrap_or_default().as_bytes()
    );
    if has_stash(repo) {
        write_bytes!(writer, b"S");
    }
}
