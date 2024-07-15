{ config, lib, pkgs, modulesPath, ... }:

{
    imports = [
        "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    ];

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    environment.systemPackages = with pkgs; [
        btop
	networkmanager
        (writeShellApplication {
        name = "nome-install";
        runtimeInputs = [ nix disko git ];
        text = ''
            set -euxo pipefail

            if [ "$#" -ne 1 ]; then
                echo "Usage: nome-install <host>"
                exit 1
            fi

            HOST=$1
            URI="github:dohjon/nome-template"

            # https://github.com/nix-community/disko/blob/master/disko
            disko --mode disko --flake "$URI#$HOST"

            # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/installer/tools/nixos-install.sh
            installArgs=(--no-channel-copy)
            nixos-install --flake "$URI#$HOST" "''${installArgs[@]}"

            git clone https://github.com/dohjon/nome-template.git /mnt/etc/nixos
        '';
        })
  ];
}
