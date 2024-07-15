{ config, lib, pkgs, modulesPath, ... }:

{
    imports = [
        "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
    ];

    # isoImage.isoBaseName = "nome_installer";

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    environment.systemPackages = with pkgs; [
        (writeShellApplication {
        name = "nome-install";
        runtimeInputs = [ nix disko git ];
        text = ''
            set -euxo pipefail

            if [ "$#" -ne 1 ]; then
                echo "Usage: nome-install <hostname>"
                exit 1
            fi

            hostname=$1
            config="https://github.com/dohjon/nome-template"

            # https://github.com/nix-community/disko/blob/master/disko
            #nix run github:nix-community/disko -- --mode disko --flake "$config#$hostname"
            disko --mode disko --flake "$config#$hostname"

            # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/installer/tools/nixos-install.sh
            installArgs=(--no-channel-copy)
            nixos-install --flake "$config#$hostname" "''${installArgs[@]}"

            git clone "$config" /mnt/home/$username/nome
        '';
        })
  ];
}

