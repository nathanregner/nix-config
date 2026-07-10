-- the builtin clojure ftplugin does `setlocal iskeyword+=?,-,*,!,+,/,=,<,>,.,:,$,%,&,|`,
-- vim.opt_local.iskeyword:remove({ "?", "-", "*", "!", "+", "/", "=", "<", ">", ".", ":", "$", "%", "&", "|" })
-- so reset iskeyword to the normal default word scope.
-- keep ":" so keywords like :foo/bar are treated as a single word
vim.opt_local.iskeyword = { "@", "48-57", "_", "192-255", ":" }
