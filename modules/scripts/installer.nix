{ pkgs }:

pkgs.writeShellApplication {
  name = "installer";
  runtimeInputs = with pkgs; [
    nix
    disko
    git
  ];
  text = ''
    print_usage_and_exit() {
        echo "Usage: $(basename "$0") <machine>"
        exit 1
    }

    confirm() {
        while true; do
            read -r -p "$1 [y/n]: " response
            case "$response" in
                [Yy]* ) return 0;;
                [Nn]* ) return 1;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    }

    if [ "$#" -ne 1 ]; then
        print_usage_and_exit
    fi
    MACHINE=$1

    nix_eval() {
        MACHINE_CONFIG="$URI#nixosConfigurations.$MACHINE.config"
        nix eval --raw "''${MACHINE_CONFIG}.$1"
    }

    URI="/root/nixos"
    URL="https://github.com/dohjon/nome-template.git"
    if [ ! -d "$URI" ]; then
        git clone "$URL" "$URI"
    fi

    ROOT_DISK=$(nix_eval "profile.rootDisk")
    USERNAME=$(nix_eval "profile.username")
    MUTABLE_USERS=$(nix_eval "profile.mutableUsers")

    if confirm "Do you want to continue? (WARNING! this will wipe disk $ROOT_DISK)"; then
        echo "Proceeding with installation on machine: $MACHINE"
    else
        echo "Installation aborted."
        exit 1
    fi

    # https://github.com/nix-community/disko/blob/master/disko
    #disko --mode disko --flake "$URI#$MACHINE"

    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/installer/tools/nixos-install.sh
    INSTALL_ARGS=(--no-channel-copy --no-write-lock-file)

    if [ "$MUTABLE_USERS" = "false" ]; then
        INSTALL_ARGS+=(--no-root-password)
    fi

    #nixos-install --flake "$URI#$MACHINE" "''${INSTALL_ARGS[@]}"

    if [ -z "$USERNAME" ]; then
        #git clone "$URL" "/mnt/etc/nixos"
    else
        #git clone "$URL" "/mnt/home/$USERNAME/nixos"
    fi

    echo "Installation done please reboot and unplug live usb..."
    echo 'systemctl reboot'
  '';
}