-- Shortcut
local opt = vim.opt

-- Encoding
opt.encoding = "utf-8"

-- Line numbers
opt.relativenumber = true
opt.number = true

-- Tabs and indentation
opt.expandtab = true
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.autoindent = true
opt.smartindent = true
opt.breakindent = true

-- Line wrapping
opt.wrap = false

-- Autocomplete
opt.wildmode = "longest:full,full"
opt.completeopt = "menuone,longest,preview" -- Set completeopt to have a better completion experience

-- Search settings
opt.ignorecase = true
opt.smartcase = true

-- Cursor line
opt.cursorline = true

-- Scrolling
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Mouse settings
opt.mouse = "a"

-- Appearance
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"
opt.fillchars:append({ eob = " " }) -- Remove ~ from end of buffer

-- Window title
opt.title = true

-- Backspace
opt.backspace = "indent,eol,start"

-- Clipboard
opt.clipboard = "unnamedplus" -- Use system clipboard

-- Split windows
opt.splitright = true
opt.splitbelow = true

opt.iskeyword:append("-")

-- Text spelling
opt.spell = false

-- Changes management
opt.confirm = true -- Ask if exiting without writing
opt.undofile = true -- Persistent undo
opt.backup = true -- Automatic backup
opt.backupdir:remove(".") -- Keep backups out of the current directory
