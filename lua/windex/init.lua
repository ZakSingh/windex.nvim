local M = {}

M.setup = function(user_config)
  -- Check if user is on Windows.
  if vim.fn.has('win32') == 1 then
    require('windex.utils').error_msg('A unix system is required for windex. Have you tried using WSL?')
    return
  end

  local utils = require('windex.utils')
  local config = require('windex.config')

  -- Setting the config options.
  if user_config ~= nil then
    utils.merge(config, user_config)
  end

  -- AUTOCMDS:

  if vim.fn.has('nvim-0.7.0') == 1 then
    local autocmd = vim.api.nvim_create_autocmd
    local augroup = vim.api.nvim_create_augroup

    -- Restore windows when terminal is exited.
    autocmd('TermClose', {
      command = "lua require('windex.maximize').restore()",
      group = augroup('windex_terminal', {}),
    })
    -- Previous window autocmds.
    autocmd('FocusGained', {
      command = "lua require('windex.movement').status_previous = 'tmux'",
      group = augroup('windex_previous_tmux', {}),
    })
    autocmd('WinLeave', {
      command = "lua require('windex.movement').status_previous = 'nvim'",
      group = augroup('windex_previous_nvim', {}),
    })
    -- Delete session file from cache.
    autocmd('VimLeave', {
      callback = utils.delete_session_files,
      group = augroup('windex_maximize', {}),
    })
  else
    -- Restore windows when terminal is exited.
    vim.cmd([[
    aug windex_terminal
    au!
    au TermClose * lua require('windex.maximize').restore()
    aug END
    ]])
    -- Previous window autocmds.
    vim.cmd([[
    aug windex_previous
    au!
    au FocusGained * lua require('windex.movement').status_previous = 'tmux'
    au WinLeave * lua require('windex.movement').status_previous = 'nvim'
    aug END
    ]])
    -- Delete session file from cache.
    vim.cmd([[
    aug windex_maximize
    au!
    au VimLeave * lua require('windex.utils').delete_session_files()
    aug END
    ]])
  end

  -- KEYMAPS:

  if config.default_keymaps then
    local keymap = vim.api.nvim_set_keymap
    local opts = { noremap = true }

    -- Enter normal mode in terminal.
    keymap('t', '<C-n>', '<C-Bslash><C-N>', opts)
    -- Check if user is using a valid version of tmux.
    if require('windex.tmux').requirement_passed() then
      -- Toggle the native terminal.
      keymap('n', '<C-Bslash>', "<Cmd>lua require('windex').toggle_terminal()<CR>", opts)
      keymap('t', '<C-Bslash>', "<Cmd>lua require('windex').toggle_terminal()<CR>", opts)
      -- Toggle maximizing the current window.
      keymap('n', '<Leader>z', "<Cmd>lua require('windex').toggle_maximize()<CR>", opts)
    else
      -- Toggle the native terminal.
      keymap('n', '<C-Bslash>', "<Cmd>lua require('windex').toggle_terminal('nvim')<CR>", opts)
      keymap('t', '<C-Bslash>', "<Cmd>lua require('windex').toggle_terminal('nvim')<CR>", opts)
      -- Toggle maximizing the current window.
      keymap('n', '<Leader>z', "<Cmd>lua require('windex').toggle_nvim_maximize()<CR>", opts)
    end
    -- Check if the user wants to use h,j,k,l or arrow keys.
    if config.arrow_keys then
      -- Move between nvim windows and tmux panes.
      keymap('n', '<Leader><Up>', "<Cmd>lua require('windex').switch_window('up')<CR>", opts)
      keymap('n', '<Leader><Down>', "<Cmd>lua require('windex').switch_window('down')<CR>", opts)
      keymap('n', '<Leader><Left>', "<Cmd>lua require('windex').switch_window('left')<CR>", opts)
      keymap('n', '<Leader><Right>', "<Cmd>lua require('windex').switch_window('right')<CR>", opts)
      -- Save and close the window in the direction selected.
      keymap('n', '<Leader>x<Up>', "<Cmd>lua require('windex').close_window('up')<CR>", opts)
      keymap('n', '<Leader>x<Down>', "<Cmd>lua require('windex').close_window('down')<CR>", opts)
      keymap('n', '<Leader>x<Left>', "<Cmd>lua require('windex').close_window('left')<CR>", opts)
      keymap('n', '<Leader>x<Right>', "<Cmd>lua require('windex').close_window('right')<CR>", opts)
    else
      -- Move between nvim windows and tmux panes.
      keymap('n', '<Leader>k', "<Cmd>lua require('windex').switch_window('up')<CR>", opts)
      keymap('n', '<Leader>j', "<Cmd>lua require('windex').switch_window('down')<CR>", opts)
      keymap('n', '<Leader>h', "<Cmd>lua require('windex').switch_window('left')<CR>", opts)
      keymap('n', '<Leader>l', "<Cmd>lua require('windex').switch_window('right')<CR>", opts)
      -- Save and close the window in the direction selected.
      keymap('n', '<Leader>xk', "<Cmd>lua require('windex').close_window('up')<CR>", opts)
      keymap('n', '<Leader>xj', "<Cmd>lua require('windex').close_window('down')<CR>", opts)
      keymap('n', '<Leader>xh', "<Cmd>lua require('windex').close_window('left')<CR>", opts)
      keymap('n', '<Leader>xl', "<Cmd>lua require('windex').close_window('right')<CR>", opts)
    end
    -- Switch to previous nvim window or tmux pane.
    keymap('n', '<Leader>;', "<Cmd>lua require('windex').previous_window()<CR>", opts)
  end

  if config.extra_keymaps then
    local keymap = vim.api.nvim_set_keymap
    local opts = { noremap = true }

    -- Create nvim panes:
    keymap('n', '<Leader>v', '<Cmd>wincmd v<CR>', opts)
    keymap('n', '<Leader>s', '<Cmd>wincmd s<CR>', opts)

    if require('windex.tmux').requirement_passed() then
      -- Create tmux panes:
      keymap('n', '<Leader>tv', "<Cmd>lua require('windex').create_pane('vertical')<CR>", opts)
      keymap('n', '<Leader>ts', "<Cmd>lua require('windex').create_pane('horizontal')<CR>", opts)
    end
  end
end

-- API:

-- Maximize:
M.toggle_nvim_maximize = function()
  require('windex.maximize').toggle('nvim')
end
M.toggle_maximize = function()
  require('windex.maximize').toggle('all')
end
M.maximize_windows = function(...)
  require('windex.maximize').maximize(...)
end
M.restore_windows = function(...)
  require('windex.maximize').restore(...)
end

-- Terminal:
M.toggle_terminal = function(...)
  require('windex.terminal').toggle(...)
end
M.enter_terminal = function(...)
  require('windex.terminal').enter(...)
end
M.exit_terminal = function()
  require('windex.terminal').exit()
end

-- Movement:
M.switch_window = function(...)
  require('windex.movement').switch(...)
end
M.close_window = function(...)
  require('windex.movement').close(...)
end
M.previous_window = function()
  require('windex.movement').previous()
end
M.create_pane = function(...)
  require('windex.movement').create_pane(...)
end

-- Window movement:
M.next_tmux_window = function()
  require('windex.movement').next_tmux_window()
end
M.prev_tmux_window = function()
  require('windex.movement').prev_tmux_window()
end

return M
