local M = {}

M.setup = function(options)
  vim.g.__windex_setup_completed = 1

  -- Check if user is on Windows.
  if vim.fn.has('win32') == 1 then
    vim.cmd([[
    echohl WarningMsg
    echo "Error: A unix system is required for 'windex' :(. Have you tried using WSL?"
    echohl None
    ]])
    return
  end

  -- Default values:
  local defaults = {
    default_keymaps = true,
    arrow_keys = false,
    disable = false,
  }

  if options == nil then
    options = defaults
  else
    for key, value in pairs(defaults) do
      if options[key] == nil then
        options[key] = value
      end
    end
  end

  -- Disable plugin.
  if options.disable == true then
    return
  end

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
  au FocusGained * lua vim.g.__windex_previous = 'tmux'
  au WinLeave * lua vim.g.__windex_previous = 'nvim'
  aug END
  ]])

  -- Delete session file from cache.
  vim.cmd([[
  aug windex_maximize
  au!
  au VimEnter * call delete(getenv('HOME') . '/.cache/nvim/.maximize_session.vim')
  au VimLeave * call delete(getenv('HOME') . '/.cache/nvim/.maximize_session.vim')
  aug END
  ]])

  local keymap = vim.api.nvim_set_keymap
  local opts = { noremap = true, silent = true }

  -- Keymaps:
  if options.default_keymaps == true then
    -- Toggle the native terminal.
    keymap('t', '<C-n>', '<C-Bslash><C-N>', opts)
    if require('windex.utils').tmux_requirement_passed() == true then
      keymap('n', '<C-Bslash>', "<Cmd>lua require('windex').toggle_terminal()<CR>", opts)
      keymap('t', '<C-Bslash>', "<Cmd>lua require('windex').toggle_terminal()<CR>", opts)
    else
      keymap('n', '<C-Bslash>', "<Cmd>lua require('windex').toggle_terminal('nvim')<CR>", opts)
      keymap('t', '<C-Bslash>', "<Cmd>lua require('windex').toggle_terminal('nvim')<CR>", opts)
    end

    -- Toggle maximizing the current window.
    if require('windex.utils').tmux_requirement_passed() == true then
      keymap('n', '<Leader>z', "<Cmd>lua require('windex').toggle_maximize()<CR>", opts)
    else
      keymap('n', '<Leader>z', "<Cmd>lua require('windex').toggle_nvim_maximize()<CR>", opts)
    end

    -- Switch to previous nvim window or tmux pane.
    keymap('n', '<Leader>;', "<Cmd>lua require('windex').previous_window()<CR>", opts)

    if options.arrow_keys == false then
      -- Move between nvim windows and tmux panes.
      keymap('n', '<Leader>k', "<Cmd>lua require('windex').switch_window('Up')<CR>", opts)
      keymap('n', '<Leader>j', "<Cmd>lua require('windex').switch_window('Down')<CR>", opts)
      keymap('n', '<Leader>h', "<Cmd>lua require('windex').switch_window('Left')<CR>", opts)
      keymap('n', '<Leader>l', "<Cmd>lua require('windex').switch_window('Right')<CR>", opts)

      -- Save and close the window in the direction selected.
      keymap('n', '<Leader>xk', "<Cmd>lua require('windex').close_window('Up')<CR>", opts)
      keymap('n', '<Leader>xj', "<Cmd>lua require('windex').close_window('Down')<CR>", opts)
      keymap('n', '<Leader>xh', "<Cmd>lua require('windex').close_window('Left')<CR>", opts)
      keymap('n', '<Leader>xl', "<Cmd>lua require('windex').close_window('Right')<CR>", opts)
    else
      -- Move between nvim windows and tmux panes.
      keymap('n', '<Leader><Up>', "<Cmd>lua require('windex').switch_window('Up')<CR>", opts)
      keymap('n', '<Leader><Down>', "<Cmd>lua require('windex').switch_window('Down')<CR>", opts)
      keymap('n', '<Leader><Left>', "<Cmd>lua require('windex').switch_window('Left')<CR>", opts)
      keymap('n', '<Leader><Right>', "<Cmd>lua require('windex').switch_window('Right')<CR>", opts)

      -- Save and close the window in the direction selected.
      keymap('n', '<Leader>x<Up>', "<Cmd>lua require('windex').close_window('Up')<CR>", opts)
      keymap('n', '<Leader>x<Down>', "<Cmd>lua require('windex').close_window('Down')<CR>", opts)
      keymap('n', '<Leader>x<Left>', "<Cmd>lua require('windex').close_window('Left')<CR>", opts)
      keymap('n', '<Leader>x<Right>', "<Cmd>lua require('windex').close_window('Right')<CR>", opts)
    end
  end
end

M.toggle_terminal = function(...)
  require('windex.terminal').toggle(...)
end
M.toggle_nvim_maximize = function()
  require('windex.maximize').toggle('nvim')
end
M.toggle_maximize = function()
  require('windex.maximize').toggle('both')
end
M.maximize_windows = function()
  require('windex.maximize').maximize()
end
M.restore_windows = function()
  require('windex.maximize').restore()
end
M.close_window = function(...)
  require('windex.movement').close(...)
end
M.switch_window = function(...)
  require('windex.movement').switch(...)
end
M.previous_window = function()
  require('windex.movement').previous()
end
M.create_tmux_pane = function(...)
  require('windex.movement').create_tmux_pane(...)
end

return M
