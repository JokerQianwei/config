-- cat ~/.config/nvim/init.lua
-- 基础设置
vim.o.number = true            -- 显示行号
vim.o.relativenumber = true    -- 相对行号
vim.o.tabstop = 4              -- tab 宽度
vim.o.shiftwidth = 4           -- 自动缩进宽度
vim.o.expandtab = true         -- 用空格代替 Tab
vim.o.termguicolors = true     -- 启用真彩色

-- 键位映射
vim.g.mapleader = " "          -- 设置 <Leader> 键为空格
vim.keymap.set("n", "<leader>w", ":w<CR>")   -- <Space>w 保存
vim.keymap.set("n", "<leader>q", ":q<CR>")   -- <Space>q 退出
vim.keymap.set("n", "<leader>x", ":wq<CR>")   -- <Space>x 保存并退出

-- ========== 插件管理 ==========
vim.opt.rtp:prepend("~/.local/share/nvim/lazy/lazy.nvim")

require("lazy").setup({
  -- 状态栏
  { "nvim-lualine/lualine.nvim", config = function()
      require("lualine").setup()
    end },

  -- 文件树
  { "nvim-tree/nvim-tree.lua", config = function()
      require("nvim-tree").setup()
      vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>")
    end },

  -- 模糊查找
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" }, config = function()
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
      vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
    end },

  -- Treesitter 语法高亮
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate", config = function()
      require("nvim-treesitter.configs").setup({
        highlight = { enable = true },
        indent = { enable = true },
      })
    end },
})