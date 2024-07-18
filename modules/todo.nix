{...}:

{
  # Limit the systemd journal to 100 MB of disk or the last 7 days of logs, whichever happens first.
  services.journald.extraConfig = ''
    SystemMaxUse=100M
    MaxFileSec=7day
  '';

  # Automatically optimize the Nix store to save space
  # by hard-linking identical files together. These savings
  # add up.
  nix.autoOptimiseStore = true;


  nix = {
    package = pkgs.nixVersions.latest;

    # Automatically run the nix store optimiser at a specific time. "If the
    # system is off during the expected execution time, the timer is executed
    # once the system is running again." The other option `auto-optimise-store =
    # true` runs optimise on every build, which in theory has some overhead.
    optimise.automatic = true;

    settings = {
      experimental-features = "nix-command flakes";
      substituters = [ "https://nix-community.cachix.org" ];
      trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
    };
    gc = {
      automatic = true;
      dates = "23:00";
      options = "--delete-older-than 30d";
    };
  };


  boot = {
    tmp.cleanOnBoot = true;

    loader = {
      # Timeout (in seconds) until loader boots the default menu item.
      timeout = 2;

      efi.canTouchEfiVariables = true;

      # Use the systemd-boot EFI boot loader.
      systemd-boot = {
        enable = true;
        # Fixes a security hole in place for the sake of backwards
        # compatibility. See description in:
        # nixpkgs/nixos/modules/system/boot/loader/systemd-boot/systemd-boot.nix
        editor = false;
      };
    };
  };
}