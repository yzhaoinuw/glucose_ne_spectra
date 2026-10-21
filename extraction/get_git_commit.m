function c = get_git_commit(repo_root)
%GET_GIT_COMMIT  Short hash of HEAD in repo_root, or 'unknown'.
[status, out] = system(sprintf('cd "%s" && git rev-parse --short HEAD 2>/dev/null', repo_root));
if status == 0, c = strtrim(out); else, c = 'unknown'; end
end
