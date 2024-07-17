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

            URI="/root/nixos"
            if [ ! -d "$URI" ]; then
                git clone https://github.com/dohjon/nome-template.git "$URI"
            fi

            HOST=$1
            # URI="github:dohjon/nome-template"
            HOST_CONFIG="$URI#nixosConfigurations.$HOST.config"
            ROOT_DISK=$(nix eval --raw "$HOST_CONFIG.system.devices.rootDisk")

            echo "Installing NixOS on $HOST with root disk $ROOT_DISK"

            # https://github.com/nix-community/disko/blob/master/disko
            # nix run github:nix-community/disko -- --mode disko --flake github:dohjon/nome-template#laptop
            disko --mode disko --flake "$URI#$HOST"

            # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/installer/tools/nixos-install.sh
            #nixos-install --flake github:dohjon/nome-template#laptop --no-channel-copy --no-write-lock-file
            installArgs=(--no-channel-copy --no-write-lock-file)

            if [ "$(nix eval "/mnt/etc/nixos#nixosConfigurations.$INSTALL_HOSTNAME.config.users.mutableUsers")" = "false" ]; then
                installArgs+=(--no-root-password)
            fi

            nixos-install --flake "$URI#$HOST" "''${installArgs[@]}"

            git clone https://github.com/dohjon/nome-template.git /mnt/etc/nixos

            # Setup/Enroll FIDO2 with LUKS
            # https://nixos.org/manual/nixos/stable/#sec-luks-file-systems
            # https://nixos.org/manual/nixos/stable/#sec-luks-file-systems-fido2
            echo "Setup/Enroll FIDO2 with LUKS using yubikey (this step requires physical access to the machine)"
            echo "plug in yubikey... "
            #systemd-cryptenroll --fido2-device=auto /dev/nvme0n1p2
            echo "first enter current passphrase for disk..."
            echo "then enter enter security token PIN..."
            echo "followed by pressing yubikey when blinking..."
            echo "finally we generate a recovery key..."
            echo "write down and store in a safe physical location..."
            #systemd-cryptenroll --recovery-key /dev/nvme0n1p2

            echo "we will now remove the passphrase so only fido2 and recovery key is available..."
            # cryptsetup luksRemoveKey /dev/nvme0n1p2
            echo "Run below command and you can verify keyslot 1 (fido2) and 2 (recovery-key) are the only keyslots used/available..."
            echo 'cryptsetup luksDump /dev/nvme0n1p2'
            # TODO: backup luks header to persist (either encrypted or unencrypted)

            echo "Installation done please reboot and unplug live usb..."
            echo 'systemctl reboot'
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
        extraConfig = ''
        AllowTcpForwarding yes
        X11Forwarding no
        AllowAgentForwarding no
        AllowStreamLocalForwarding no
        AuthenticationMethods publickey
        '';
    };
}
