-- Don't include this file, we should manually include it via
-- require("harpoon.dev").reload();
--
-- A quick mapping can be setup using something like:
-- :nmap <leader>rr :lua require("harpoon.dev").reload()<CR>
local M = {}

M.reload = function()
    require("plenary.reload").reload_module("neovim-irc-ui");
end

return M

