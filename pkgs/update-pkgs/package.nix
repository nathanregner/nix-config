{ writeBabashkaApplication }:
writeBabashkaApplication {
  name = "update-pkgs";
  text = builtins.readFile ./update-pkgs.clj;
}
