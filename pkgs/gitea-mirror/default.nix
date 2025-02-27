{ writeBabashkaApplication }:
writeBabashkaApplication {
  name = "gitea-sync.clj";
  text = builtins.readFile ./main.clj;
}
