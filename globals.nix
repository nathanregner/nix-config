# TODO: generate sops.yaml
{ lib }:
{
  ssh = rec {
    hostKeys = rec {
      enceladus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIByCYpEo+AjtM2kWxxr5C9Mp3tm1PyVDVD8BGesKTi85";
      enceladus-linux-vm = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJBWcxb/Blaqt1auOtE+F8QUWrUotiC5qBJ+UuEWdVCb";
      "[localhost]:31022" = enceladus-linux-vm;
      iapetus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOhre0L0AW87qYkI5Os8U2+DS5yvAOnjpEY+Lmn5f0l7";
      sagittarius = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIQOaeRY07hRIPpeFYRWoQOzP+toxZjveC5jVHF+vpIj";
      voron = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJwRmpXQaCQ57F9KBmWAd5nPLSNh0gEro7i8JPDal8XL";
    };

    userKeys = {
      nregner = {
        "nregner@enceladus" =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJN0UxPvRjkqYdq8OFtzO/borc4lU4QNYSJiGhgx3MkI";
        "nregner@iapetus" =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDk7uVEehfyhAZUvZbvH5Kw85MzLyYqVdTOMBXsmBeLx";
        "nregner@sagittarius" =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIArpJ0oIqZ8amBOGjwPSoxAXMzgNeyu8fV9pfQmsGl+i";
      };
      hydra = {
        "hydra-queue-runner@sagittarius" =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKQ05+x+kcn+bkp1q34g6p0lHxo6QDGujUnsYpUOSBSK";
      };
    };

    allKeys = hostKeys // lib.mergeAttrsList (builtins.attrValues userKeys);

    knownHosts = lib.mapAttrs (name: value: { publicKey = value; }) hostKeys;
  };
}
// builtins.fromJSON (builtins.readFile ./globals.json)
