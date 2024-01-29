--[[
--
-- This file is not required for your own configuration,
-- but helps people determine if their system is setup correctly.
--
--]]

local check_version = function()
  if vim.version().minor == 11 then
    local tmp = {
      major = vim.version().major,
      minor = vim.version().minor,
      patch = vim.version().patch,
      prerelease = vim.version().prerelease,
    }
    vim.health.ok('Neovim version: ' .. vim.inspect(tmp))
    return true
  else
    local verstr = string.format('%s.%s.%s', vim.version().major, vim.version().minor, vim.version().patch)
    vim.health.error(string.format('Neovim %s is outdated. Upgrade to latest nightly', verstr))
    return false
  end
end

local check_external_reqs = function()
  for _, exe in ipairs { 'git', 'make', 'unzip', 'rg', 'fzf', 'fswatch' } do
    local is_executable = vim.fn.executable(exe) == 1
    if is_executable then
      vim.health.ok(string.format("Found executable: '%s'", exe))
    else
      vim.health.warn(string.format("Could not find executable: '%s'", exe))
    end
  end

  return true
end

local M = {}
M.check = function()
  local uv = vim.uv or vim.loop
  vim.health.info('System Information: ' .. vim.inspect(uv.os_uname()))

  vim.health.start 'Use nightly'
  check_version()
  vim.health.start 'Cli dependencies'
  check_external_reqs()
end

return M
