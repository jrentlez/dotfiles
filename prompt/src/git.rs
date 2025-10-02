use std::io::Write;

use git2::{Branch, BranchType, Commit, ErrorCode, Repository, RepositoryState, StatusOptions};

use crate::{ansi::Shell, strip_prefix_bytes, write_bytes};

struct AheadBehind {
    ahead: usize,
    behind: usize,
}
impl AheadBehind {
    fn read<'b>(repo: &Repository, local: &Branch<'b>, upstream: &Branch<'b>) -> Self {
        let local_id = local.get().target().expect("HEAD points to a reference");
        let upstream_id = upstream
            .get()
            .target()
            .expect("upstream points to a reference");

        let (ahead, behind) = repo
            .graph_ahead_behind(local_id, upstream_id)
            .expect("Has ahead behind count");

        Self { ahead, behind }
    }

    fn as_bytes(&self) -> &[u8] {
        if self.ahead > 0 && self.behind > 0 {
            b"AB"
        } else if self.ahead > 0 {
            b"A"
        } else if self.behind > 0 {
            b"B"
        } else {
            b""
        }
    }
}

enum Head<'repo> {
    Unborn,
    Branch(Branch<'repo>),
    Commit(Commit<'repo>),
}
impl<'repo> Head<'repo> {
    fn read(repo: &'repo Repository) -> Self {
        match repo.head() {
            Ok(head) => {
                let short = head.shorthand().expect("HEAD has shorthand");
                if short == "HEAD" {
                    let commit = head
                        .peel_to_commit()
                        .expect("Detached head points to commit");
                    Self::Commit(commit)
                } else {
                    let branch = repo
                        .find_branch(short, BranchType::Local)
                        .expect("Branch is HEAD");
                    Self::Branch(branch)
                }
            }
            Err(err) => match err.code() {
                ErrorCode::UnbornBranch => Head::Unborn,
                code => unreachable!("{code:?}: {err}"),
            },
        }
    }

    fn write(&self, writer: &mut impl Write, repo: &'repo Repository) -> Option<AheadBehind> {
        match Head::read(repo) {
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
                let Ok(upstream) = local.upstream() else {
                    write_bytes!(writer, local_name);
                    return None;
                };

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
                    write_bytes!(writer, upstream_name_with_remote);
                } else {
                    write_bytes!(writer, local_name, b":", upstream_name_with_remote);
                }

                Some(AheadBehind::read(repo, &local, &upstream))
            }
        }
    }
}

fn write_repo_state(writer: &mut impl Write, repo: &Repository) -> Option<AheadBehind> {
    let state = match repo.state() {
        RepositoryState::Clean => {
            return Head::read(repo).write(writer, repo);
        }
        RepositoryState::Merge => "merge",
        RepositoryState::Revert => "revert",
        RepositoryState::RevertSequence => "revert-sequence",
        RepositoryState::CherryPick => "cherry-pick",
        RepositoryState::CherryPickSequence => "cherry-pick-sequence",
        RepositoryState::Bisect => "bisect",
        RepositoryState::Rebase => "rebase",
        RepositoryState::RebaseInteractive => "rebase-interactive",
        RepositoryState::RebaseMerge => "rebase-merge",
        RepositoryState::ApplyMailbox => "apply-mailbox",
        RepositoryState::ApplyMailboxOrRebase => "apply-mailbox-or-rebase",
    };
    write_bytes!(writer, state.as_bytes());
    None
}

fn write_git_status(writer: &mut impl Write, repo: &Repository) {
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

pub fn git(writer: &mut impl Write, repo: &Repository, shell: Shell) {
    write_bytes!(writer, shell.fg_dim());
    let ahead_behind = write_repo_state(writer, repo);

    write_bytes!(writer, shell.yellow_normal());
    write_git_status(writer, repo);

    write_bytes!(writer, shell.fg_normal());
    if let Some(ab) = ahead_behind {
        write_bytes!(writer, ab.as_bytes());
    }
    if has_stash(repo) {
        write_bytes!(writer, b"S");
    }
}
