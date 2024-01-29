local get_files = function(base_commit, base_path, upstream_path)
  local base_url = 'https://raw.githubusercontent.com/nvim-lua/kickstart.nvim/' .. base_commit .. '/init.lua'
  local latest_url = 'https://raw.githubusercontent.com/nvim-lua/kickstart.nvim/master/init.lua'
  local bwait = vim.system { 'curl', base_url, '--output', base_path }
  local uwait = vim.system { 'curl', latest_url, '--output', upstream_path }
  return bwait, uwait
end

local diff_merge = function(base_commit, current, new_path)
  local base = os.tmpname()
  local upstream = os.tmpname()
  local bwait, uwait = get_files(base_commit, base, upstream)

  local new = io.open(new_path, 'w')
  if not new then
    bwait:wait()
    uwait:wait()
    os.remove(base)
    os.remove(upstream)
    error('Could not write to ' .. new_path)
  end
  bwait:wait()
  uwait:wait()
  local out = vim
    .system({ 'diff3', '-m', '-L current', '-L base', '-L upstream', current, base, upstream }, {
      stdout = function(_, data)
        if data then
          new:write(data)
        end
      end,
    })
    :wait()
  new:close()
  os.remove(base)
  os.remove(upstream)
  return out
end

local print_summary = function(code, current, new, base_commit)
  local diff_url = 'https://github.com/nvim-lua/kickstart.nvim/compare/' .. base_commit .. '..master'
  local commit_url = 'https://github.com/nvim-lua/kickstart.nvim/commits/master'

  if code > 0 then
    vim.notify(
      'Changes from kickstart.nvim were merged and saved at '
        .. new
        .. '\nThere were conflicts!\nManually resolve them before applying the new config!!!!!\nkickstart-base diff: '
        .. diff_url
        .. '\nNew kickstart-base commits: '
        .. commit_url,
      vim.log.levels.WARN
    )
    return
  end

  local d = vim.system({ 'diff', '-s', current, new }):wait()
  if d.code == 0 then
    os.remove(new)
    vim.notify('Your `init.lua` and the result of the merge are identical.', vim.log.levels.INFO)
    return
  end

  vim.notify(
    'Changes from kickstart.nvim were merged and saved at '
      .. new
      .. "\nThere were no conflicts :)\nDon't forget to update the commit hash before applying the new config!\nkickstart-base diff: "
      .. diff_url
      .. '\nNew kickstart-base commits: '
      .. commit_url,
    vim.log.levels.WARN
  )
end

local M = {}
M.update = function(base_commit)
  local new = vim.fn.stdpath 'config' .. '/init.new.lua'
  local current = vim.fn.stdpath 'config' .. '/init.lua'
  local out = diff_merge(base_commit, current, new)
  if out.code < 0 or out.code >= 2 then
    error(out.stderr)
  end
  print_summary(out.code, current, new, base_commit)
end

return M
