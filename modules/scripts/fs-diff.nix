{ pkgs, config }:

pkgs.writeShellApplication {
  name = "fs-diff";
  runtimeInputs = with pkgs; [ btrfs-progs ];
  text = ''
    print_error_and_exit() {
        >&2 echo "$1"
        exit 1
    }

    if [ "$(id -u)" -ne 0 ]; then
        print_error_and_exit "Must run as superuser to be able to mount main Btrfs volume"
    fi

    MOUNTDIR=$(mktemp -d)
    DEVICE="${config.profile.luksMappedDevice}"
    BLANK_ROOT_SNAPSHOT="''${MOUNTDIR}/root-blank"
    ROOT_SUBVOL="''${MOUNTDIR}/root"

    # mount the btrfs root volume to tmp dir so we can compare it
    mount -t btrfs -o subvol=/ ''${DEVICE} "''${MOUNTDIR}"

    OLD_TRANSID=$(btrfs subvolume find-new "''${BLANK_ROOT_SNAPSHOT}" 9999999 | awk '{print $NF}')

    btrfs subvolume find-new "$ROOT_SUBVOL" "$OLD_TRANSID" |
      sed '$d' |
      cut -f17- -d' ' |
      sort |
      uniq |
      while read -r path;
      do
        path="/$path"
        if [ -L "$path" ];
        then
          : # The path is a symbolic link, so is probably handled by NixOS
        elif [ -d "$path" ];
        then
          : # The path is a directory; ignore
        else
          echo "$path"
        fi
      done

    umount "$MOUNTDIR"
    rm -r  "$MOUNTDIR"
  '';
}