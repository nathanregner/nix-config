nvim --headless -c "PlenaryBustedDirectory $(realpath tests) { nvim_cmd = '$(realpath ~/.nix-profile/bin/nvim)', init = '~/.config/nvim/init.lua' }"
