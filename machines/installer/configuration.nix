{ config, lib, pkgs, modulesPath, ... }:

{
    imports = [
        "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
        # "${modulesPath}/installer/cd-dvd/installation-cd-graphical-gnome.nix"
    ];

    environment.systemPackages = with pkgs; [
        gitMinimal
        (callPackage ../../modules/scripts/installer.nix {})
    ];

    environment.shellAliases = {
        ll  = "ls -alh";
        build-iso  = "git clone https://github.com/dohjon/nome-template.git /root/nixos && cd /root/nixos && time nix build --no-link --print-out-paths .#nixosConfigurations.installer.config.system.build.isoImage";
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
        extraConfig = ''
        AllowTcpForwarding yes
        X11Forwarding no
        AllowAgentForwarding no
        AllowStreamLocalForwarding no
        AuthenticationMethods publickey
        '';
    };
}
