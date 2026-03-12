#!/usr/bin/env bash
cd "$(dirname "$0")" || exit 1
nvim --headless -c "PlenaryBustedDirectory lua/user"
