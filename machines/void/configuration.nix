{ config, lib, pkgs, inputs, machine, ... }:

{
  imports = [
    ./disks.nix
    ./hardware.nix
    ./ephemeral.nix
  ];

  # Custom
  profile = {
    username = "dohjon";
    hostname = "${machine}";
    rootDisk = "/dev/nvme0n1";
    luksMappedDevice = "/dev/mapper/crypted";
  };

  # Use systemd boot (EFI only)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # https://github.com/NixOS/nixos-hardware/blob/master/framework/13-inch/7040-amd/README.md#updating-firmware
  services.fwupd.enable = true;

  # https://nixos.org/manual/nixos/stable/#sec-luks-file-systems-fido2-systemd
  boot.initrd = {
    # Use systemd in stage 1 (new). Instead of scripted stage 1 (old).
    # https://nixos.org/manual/nixos/stable/#sec-luks-file-systems-fido2-systemd
    systemd.enable = true;
  	luks.devices."${lib.removePrefix "/dev/mapper/" config.profile.luksMappedDevice}" = {
      crypttabExtraOpts = [ "fido2-device=auto" ];
    };
  };

  networking.networkmanager.enable = true;
  networking.hostName = "${config.profile.hostname}";

  # Don't allow mutation of users outside of the config.
  users.mutableUsers = false;
  users.users."${config.profile.username}" = {
  	isNormalUser = true;
  	extraGroups = [ "wheel" "networkmanager" ];
  	initialPassword = "12345";
  };

  system.stateVersion = "24.05";
}
