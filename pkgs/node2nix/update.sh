#!/usr/bin/env bash

cd "$(dirname "$0")"
nix run nixpkgs#node2nix -- -i node-packages.json --include-peer-dependencies
