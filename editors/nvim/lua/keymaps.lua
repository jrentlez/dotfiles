-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

---@alias KeyMode 'n' | 'i' | 't' | 'v'
---@alias ConfigKeymap string[]
---@alias ConfigKeymaps table<KeyMode, ConfigKeymap[]>

local H = {}

---@param mode KeyMode
---@param keymap ConfigKeymap
H.add = function(mode, keymap)
  local lhs = keymap[1]
  local rhs = keymap[2]
  local desc = keymap[3]
  vim.keymap.set(mode, lhs, rhs, { desc = desc })
end

---@param lhs string
---@param scope string
---@param desc string
---@return ConfigKeymap
H.pick_keymap_lsp = function(lhs, scope, desc)
  return {
    lhs,
    function()
      MiniExtra.pickers.lsp({ scope = scope }, {})
    end,
    desc,
  }
end

---@param keymaps_table table<KeyMode, ConfigKeymap[]>
H.add_table = function(keymaps_table)
  for mode, keymaps in pairs(keymaps_table) do
    for _, keymap in ipairs(keymaps) do
      H.add(mode, keymap)
    end
  end
end

local M = {}

---@param keymaps table<KeyMode, ConfigKeymap[]> | fun(): table<KeyMode, ConfigKeymap[]>
M.add = function(keymaps)
  if type(keymaps) == 'function' then
    H.add_table(keymaps())
  else
    H.add_table(keymaps)
  end
end

vim.opt.hlsearch = true

-- Set <space> as the leader key
-- See `:help mapleader`
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

M.basic = {
  n = {
    -- Set highlight on search, but clear on pressing <Esc> in normal mode
    { '<Esc>', '<cmd>nohlsearch<cr>' },
    -- TIP: Disable arrow keys in normal mode
    { '<left>', '<cmd>echo "Use h to move!!"<cr>' },
    { '<right>', '<cmd>echo "Use l to move!!"<CR>' },
    { '<up>', '<cmd>echo "Use k to move!!"<CR>' },
    { '<down>', '<cmd>echo "Use j to move!!"<CR>' },
    -- Diagnostic keymaps
    { '<leader>e', vim.diagnostic.open_float, 'Show diagnostic [E]rror messages' },
    { '<leader>q', vim.diagnostic.setloclist, 'Open diagnostic [Q]uickfix list' },
    -- Manage buffers
    { 'gb', '<cmd>bnext<cr>', 'Goto next buffer' },
    { 'gB', '<cmd>bprevious<cr>', 'Goto previous buffer' },
    { '<leader>bd', '<cmd>bdelete<cr>', 'Close current buffer' },
    -- Manage tabs
    { '<leader>to', '<cmd>tabnew<cr>', 'Open new tab' },
    { '<leader>tx', '<cmd>tabclose<cr>', 'Close tab' },
    { '<leader>tf', '<cmd>tabnew %<cr>', 'Open current buffer in new tab' },
  },
  t = {
    -- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
    -- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
    -- is not what someone will guess without a bit more experience.
    --
    -- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
    -- or just use <C-\><C-n> to exit terminal mode
    { '<Esc><Esc>', '<C-\\><C-n>', 'Exit terminal mode' },
  },
} ---@as ConfigKeymaps

M.which_key = { -- Useful plugin to show you pending keybinds.
  'folke/which-key.nvim',
  event = 'UIEnter',
  config = function()
    require('which-key').setup()

    -- Document existing key chains
    require('which-key').register {
      ['<leader>c'] = { name = '[C]ode', _ = 'which_key_ignore' },
      ['<leader>d'] = { name = '[D]ocument', _ = 'which_key_ignore' },
      ['<leader>r'] = { name = '[R]ename', _ = 'which_key_ignore' },
      ['<leader>s'] = { name = '[S]earch', _ = 'which_key_ignore' },
      ['<leader>w'] = { name = '[W]orkspace', _ = 'which_key_ignore' },
      ['<leader>t'] = { name = '[T]oggle', _ = 'which_key_ignore' },
      ['<leader>h'] = { name = 'Git [H]unk', _ = 'which_key_ignore' },
    }
    -- visual mode
    require('which-key').register({
      ['<leader>h'] = { 'Git [H]unk' },
    }, { mode = 'v' })
  end,
}

M.lsp = {
  n = {
    -- Rename the variable under your cursor.
    -- Most Language Servers support renaming across files, etc.
    { '<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame' },
    -- Execute a code action, usually your cursor needs to be on top of an error
    -- or a suggestion from your LSP for this to activate.
    { '<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction' },
    -- WARN: This is not Goto Definition, this is Goto Declaration.
    --  For example, in C this would take you to the header.
    { 'gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration' },

    H.pick_keymap_lsp('gd', 'definition', '[G]oto [D]efinition'),
    H.pick_keymap_lsp('gr', 'references', '[G]oto [R]eferences'),
    H.pick_keymap_lsp('gI', 'implementation', '[G]oto [I]implementation'),
    H.pick_keymap_lsp('<leader>sD', 'type_definition', '[S]earch type [D]efinition'),
    H.pick_keymap_lsp('<leader>ss', 'document_symbol', '[S]earch document [S]ymbols'),
    H.pick_keymap_lsp('<leader>sw', 'workspace_symbol', '[S]earch [W]orkspace Symbols'),
  },
}

M.mini = function()
  local pickers = vim.tbl_deep_extend('error', MiniPick.builtin, MiniExtra.pickers)
  return {
    n = {
      -- mini.files
      {
        '<leader>f',
        function()
          MiniFiles.open(vim.api.nvim_buf_get_name(0))
        end,
        'Open [F]ile explorer',
      },
      -- mini.pick
      { '<leader>sh', pickers.help, '[S]earch [H]elp' },
      { '<leader>sk', pickers.keymaps, '[S]earch [K]eymaps' },
      { '<leader>sf', pickers.files, '[S]earch [F]iles' },
      { '<leader>sg', pickers.grep_live, '[S]earch by [G]rep' },
      { '<leader>sd', pickers.diagnostic, '[S]earch [D]iagnostics' },
      { '<leader>sr', pickers.resume, '[S]earch [R]esume' },
      { '<leader>s.', pickers.oldfiles, '[S]earch recent files ("." for repeat)' },
      { '<leader><leader>', pickers.buffers, '[S]earch [B]uffers' },
      {
        '<leader>/',
        function()
          return pickers.buf_lines({ scope = 'current' }, {})
        end,
        '[/] Fuzzily search in the current buffer',
      },
      {
        '<leader>sp',
        function()
          return MiniPick.start {
            source = {
              items = vim.tbl_keys(pickers),
              name = 'Pickers',
              choose = function(picker)
                pickers[picker]({}, {})
              end,
            },
          }
        end,
        '[S]earch [P]ickers',
      },
      {
        '<leader>sn',
        function()
          return pickers.files({}, {
            source = {
              cwd = vim.fn.stdpath 'config',
            },
          })
        end,
        '[S]earch [N]eovim config files',
      },
      { '<leader>s/', pickers.buf_lines, '[S]earch [/] fuzzily in buffers ' },
      -- mini.diff
      { 'go', MiniDiff.toggle_overlay, 'Toggle Mini[G]it [O]verlay' },
    },
  }
end

return M
