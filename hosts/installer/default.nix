{ config, lib, pkgs, modulesPath, ... }:

{
    imports = [
        "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
        # "${modulesPath}/installer/cd-dvd/installation-cd-graphical-gnome.nix"
    ];

    environment.systemPackages = with pkgs; [
        gitMinimal
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
            # nix run github:nix-community/disko -- --mode disko --flake github:dohjon/nome-template#laptop
            disko --mode disko --flake "$URI#$HOST"

            # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/installer/tools/nixos-install.sh
            installArgs=(--no-channel-copy)
            nixos-install --flake "$URI#$HOST" "''${installArgs[@]}"

            git clone https://github.com/dohjon/nome-template.git /mnt/etc/nixos
        '';
        })
    ];

    environment.shellAliases = {
        ll  = "ls -alh";
    };

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    users.users.root = {
        openssh.authorizedKeys.keys = [
            # https://github.com/dohjon.keys
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM1lTOnrkoGlToh6Mtga3/wh9/knokBlsQKU3MSC3CcB"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP8XIwh2g+vCI1pVDkF0bHAO013jN2fSC++plEpgxibd"
        ];
    };

    services.openssh = {
        enable = true;
        allowSFTP = false;
        settings.PasswordAuthentication = false;
        settings.KbdInteractiveAuthentication = false;
        challengeResponseAuthentication = false;
        extraConfig = ''
        AllowTcpForwarding yes
        X11Forwarding no
        AllowAgentForwarding no
        AllowStreamLocalForwarding no
        AuthenticationMethods publickey
        '';
    };
}
