-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Enable syntax highlighting.
vim.cmd("syntax enable")

-- Line numbers (absolute). Add `vim.opt.relativenumber = true` for hybrid.
vim.opt.number = true

-- Disable mouse support so the terminal handles selection (drag-to-highlight
-- and copy work normally). Neovim defaults to mouse="nvi", which intercepts it.
vim.opt.mouse = ""

-- Personal desert colorscheme (~/.config/nvim/colors/desert_deva.vim).
-- Force the cterm (256-color) palette so Neovim matches Vim. termguicolors is
-- explicitly disabled (not just omitted) because Neovim auto-enables truecolor
-- when it sees COLORTERM=truecolor, which makes the scheme use its gui* colors
-- (beige statusline, olive keywords) instead of the cterm* ones Vim uses.
vim.opt.termguicolors = false
vim.cmd.colorscheme("desert_deva")

-- desert_deva only defines the parent `Constant` group (brown in cterm) and
-- relies on the classic Vim default where String/Character/Number/Boolean/Float
-- link to Constant. Neovim ships its own defaults for these (String comes out
-- green), so re-link them to Constant to match Vim. `default` lets a later
-- explicit rule win; we omit it here to force the link over Neovim's default.
for _, group in ipairs({ "String", "Character", "Number", "Boolean", "Float" }) do
  vim.api.nvim_set_hl(0, group, { link = "Constant" })
end

-- Belt-and-suspenders: some plugins (e.g. fzf) or later config can flip
-- termguicolors back on. Force it off again after startup completes.
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.opt.termguicolors = false
  end,
})

-- Find a tags file in the current directory or any ancestor (walk up to root).
-- This lets native tag commands (<C-]>, :tag) work from anywhere in the tree.
vim.opt.tags = { "./tags", "tags;/" }

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
{
  'nvim-telescope/telescope.nvim', version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
  },
  config = function()
    require("telescope").load_extension("fzf")  -- activate fzf-native
    local builtin = require("telescope.builtin")

    local pickers    = require("telescope.pickers")
    local finders    = require("telescope.finders")
    local conf       = require("telescope.config").values
    local actions    = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    -- Jump-to-definition with a Telescope UI, but WITHOUT loading the whole
    -- tags file. vim.fn.taglist() uses nvim's native tag engine (the same fast,
    -- exact lookup behind :tag) to fetch only the entries whose name matches the
    -- word under the cursor. We then feed that small result set to a Telescope
    -- picker. builtin.tags is avoided here because it ingests and fuzzy-ranks
    -- the entire multi-million-entry file, which is slow and imprecise.
    local function tag_jump()
      local word = vim.fn.expand("<cword>")
      if word == "" then
        vim.notify("No word under cursor", vim.log.levels.WARN)
        return
      end

      -- Anchor the pattern so we get exact-name matches, not substrings.
      local matches = vim.fn.taglist("^" .. vim.fn.escape(word, "\\/.*$^~[]") .. "$")
      if vim.tbl_isempty(matches) then
        vim.notify("tag not found: " .. word, vim.log.levels.WARN)
        return
      end

      -- Single match: jump straight there, just like native <C-]>.
      if #matches == 1 then
        vim.cmd("tag " .. word)
        return
      end

      -- Multiple matches: show the Telescope picker.
      pickers.new({}, {
        prompt_title = "Tags: " .. word,
        finder = finders.new_table({
          results = matches,
          entry_maker = function(t)
            local kind = t.kind or "?"
            return {
              value = t,
              -- Show kind + defining file so duplicates are distinguishable.
              display = string.format("%-2s %s", kind, t.filename),
              ordinal = (t.filename or "") .. " " .. kind,
              filename = t.filename,
            }
          end,
        }),
        sorter = conf.generic_sorter({}),
        previewer = conf.grep_previewer({}),
        attach_mappings = function(prompt_bufnr)
          actions.select_default:replace(function()
            local entry = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            local t = entry.value
            -- Open the defining file, then run the tag's search command to land
            -- on the exact line (the ex-command in the tags "cmd" field).
            vim.cmd("edit " .. vim.fn.fnameescape(t.filename))
            if t.cmd and t.cmd ~= "" then
              -- t.cmd is usually a /^...$/ search pattern; execute it silently.
              local ok = pcall(function() vim.cmd("keepjumps " .. t.cmd) end)
              if not ok then
                -- Fall back to native tag jump if the search cmd fails.
                pcall(vim.cmd, "tag " .. word)
              end
            end
          end)
          return true
        end,
      }):find()
    end

    -- <C-]>: word-under-cursor jump with Telescope UI for ambiguous tags.
    vim.keymap.set("n", "<C-]>", tag_jump, { desc = "Tags (jump, Telescope UI)" })

    -- g]: fuzzy browse across all tags (fine for interactive searching).
    vim.keymap.set("n", "g]", builtin.tags, { desc = "Tags (fuzzy browse)" })

    -- <C-o>: Telescope file finder. NOTE: this shadows the built-in normal-mode
    -- <C-o> (jumplist-back). Insert-mode <C-o> is untouched. Use <C-i>/<Tab> to
    -- go forward in the jumplist; jumplist-back is available via :ju or a remap.
    vim.keymap.set("n", "<C-o>", builtin.find_files, { desc = "Find files (Telescope)" })
  end,
}
  },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "habamax" } },
  -- automatically check for plugin updates
  checker = { enabled = true },
})
