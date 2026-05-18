{
  programs.btop = {
    enable = true;
    settings = {
      mem_graphs = false;
      proc_per_core = true;
      show_swap = true;
      swap_disk = false;
      show_disks = false;
      vim_keys = true;
    };
  };
  catppuccin.btop.enable = true;
}
