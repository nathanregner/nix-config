prev: pkg: # #
args: neovim-unwrapped:
(pkg args neovim-unwrapped).overrideAttrs {
  dontStrip = true;
  dontFixup = true;
}
