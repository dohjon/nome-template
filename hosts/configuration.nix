{ config, lib, pkgs, ... }:

{
  imports = [
    ./disks.nix
    ./hardware.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  fileSystems."/state".neededForBoot = true;
  fileSystems."/persist".neededForBoot = true;

  #boot.initrd = {
  #	luks.devices."enc".crypttabExtraOpts = [ "fido2-device=auto" ];
  #	systemd.enable = true; 
  #};
    
  networking.networkmanager.enable = true;
  networking.hostName = "nixos";
  users.mutableUsers = false;
  users.users.nixos = {
  	isNormalUser = true;
  	extraGroups = [ "wheel" "networkmanager" ];
  	initialPassword = "12345";
  };

  system.stateVersion = "24.05";
}
