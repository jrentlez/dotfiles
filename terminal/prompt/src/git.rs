use git2::{Branch, BranchType, Commit, ErrorCode, Repository, StatusOptions};

use crate::color;

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

fn git_status(repo: &Repository) -> String {
    let mut opts = StatusOptions::new();
    opts.include_untracked(true)
        .recurse_untracked_dirs(true)
        .renames_index_to_workdir(true)
        .renames_from_rewrites(true)
        .renames_head_to_index(true);

    let stats = match repo.statuses(Some(&mut opts)) {
        Ok(stats) => stats,
        Err(error) => match error.code() {
            git2::ErrorCode::BareRepo => return "".to_string(),
            code => {
                panic!("{code:?}: {error}")
            }
        },
    };
    let stat = match stats
        .into_iter()
        .map(|stat| stat.status())
        .reduce(|a, b| a | b)
    {
        Some(stat) => stat,
        None => return "".to_string(),
    };

    let mut s = "".to_string();
    if stat.is_conflicted() {
        s.push('⇄');
    }
    if stat.is_wt_new() {
        s.push('?');
    }
    if stat.is_wt_modified() {
        s.push('!');
    }
    if stat.is_index_new() || stat.is_index_modified() {
        s.push('+');
    }
    if stat.is_wt_renamed()
        || stat.is_wt_typechange()
        || stat.is_index_renamed()
        || stat.is_index_typechange()
    {
        s.push('»');
    }
    if stat.is_wt_deleted() || stat.is_index_deleted() {
        s.push('✖');
    }
    color::PURPLE.to_string() + &s
}

fn has_stash(repo: &Repository) -> bool {
    let stash_reflog = match repo.reflog("refs/stash") {
        Ok(reflog) => reflog,
        Err(_) => return false,
    };
    !stash_reflog.is_empty()
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
        "⇕"
    } else if ahead > 0 {
        "⇡"
    } else if behind > 0 {
        "⇣"
    } else {
        ""
    };
    Some(Upstream {
        branch: upstream,
        ahead_behind,
    })
}

pub fn git(repo: &Repository) -> String {
    let (head, ahead_behind) = match read_head(repo) {
        Head::Unborn => (
            repo.find_reference("HEAD")
                .expect("Can read head file")
                .symbolic_target()
                .expect("Is symbolic and UTF8")
                .strip_prefix("refs/heads/")
                .expect("target starts with refs/heads/")
                .to_string(),
            None,
        ),
        Head::Commit(commit) => (
            commit
                .into_object()
                .short_id()
                .expect("commit has short id")
                .as_str()
                .expect("UTF8")
                .to_string(),
            None,
        ),
        Head::Branch(local) => {
            let local_name = local
                .name()
                .expect("Branch has name")
                .expect("UTF8")
                .to_string();
            match read_upstream(repo, &local) {
                Some(Upstream {
                    branch: upstream,
                    ahead_behind,
                }) => {
                    let remote_prefix = repo
                        .branch_remote_name(upstream.get().name().expect("UTF8"))
                        .expect("Already verified existing upstream")
                        .as_str()
                        .expect("UTF8")
                        .to_string()
                        + "/";
                    let upstream_full_name =
                        upstream.name().expect("Branch has name").expect("UTF8");

                    let upstream_branch_name = upstream_full_name
                        .strip_prefix(&remote_prefix)
                        .expect("upstream name starts with remote");

                    if local_name == upstream_branch_name {
                        (upstream_full_name.to_string(), Some(ahead_behind))
                    } else {
                        (local_name + ":" + upstream_full_name, Some(ahead_behind))
                    }
                }
                None => (local_name, None),
            }
        }
    };

    let stash = if has_stash(repo) { "$" } else { "" };

    " ".to_string()
        + color::FG_DIM
        + &head
        + color::RESET
        + &git_status(repo)
        + color::CYAN
        + ahead_behind.unwrap_or_default()
        + stash
}
