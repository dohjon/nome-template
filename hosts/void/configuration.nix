{ config, lib, pkgs ... }:

{
  imports = [
    ./disks.nix
    ./hardware.nix
    ../../modules/nixos/system/devices.nix
  ];

  # Custom
  system.devices = {
    rootDisk = "/dev/nvme0n1";
    luksMappedDevice = "/dev/mapper/crypted";
  };

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # https://github.com/NixOS/nixos-hardware/blob/master/framework/13-inch/7040-amd/README.md#updating-firmware
  services.fwupd.enable = true;

  # https://nixos.org/manual/nixos/stable/#sec-luks-file-systems-fido2-systemd
  boot.initrd = {
    systemd.enable = true;
  	luks.devices."${lib.removePrefix "/dev/mapper/" config.system.devices.luksMappedDevice}" = {
      crypttabExtraOpts = [ "fido2-device=auto" ];
    };
  };

  networking.networkmanager.enable = true;
  networking.hostName = "void";
  
  users.mutableUsers = false;
  users.users.dohjon = {
  	isNormalUser = true;
  	extraGroups = [ "wheel" "networkmanager" ];
  	initialPassword = "12345";
  };

  system.stateVersion = "24.05";
}
