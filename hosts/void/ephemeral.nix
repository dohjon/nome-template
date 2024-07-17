{ config, lib, pkgs, inputs, ... }:

{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  # /persist is the location you plan to store the files
  environment.persistence."/persist" = {
    # Hide these mount from the sidebar of file managers
    hideMounts = true;

    # Folders you want to map
    directories = [
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
    ];

    # Files you want to map
    files = [
      "/etc/machine-id"
    ];

    # Similarly, you can map files and folders in users' home directories
    # users.dohjon = {
    #   directories = [
    #     # Personal files
    #     "Desktop"
    #     "Documents"
    #     "Downloads"
    #     "Music"
    #     "Pictures"
    #     "Videos"

    #     # Config folders
    #     ".cache"
    #     ".config"
    #     ".gnupg"
    #     ".local"
    #     ".ssh"
    #   ];
    #   files = [ ];
    # };
  };

  # Stage 1: systemd
  # man machine-id
  # boot.initrd.systemd.services.persisted-files = {
  #   description = "Hard-link persisted files from /persist";

  #   wantedBy = [ "initrd.target" ]; # we want this to run in stage 1 and stage 2 will not happen until initrd.target is reached and done
  #   after = [ "sysroot.mount"]; # we need /sysroot to be mounted

  #   unitConfig = {
  #     AssertPathExists = "/persist/etc/machine-id";
  #     DefaultDependencies = false;
  #   };

  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #   };

  #   script = ''
  #     mkdir -p /sysroot/etc/
  #     ln -snfT /persist/etc/machine-id /sysroot/etc/machine-id
  #   '';
  # };

  # Stage 1: systemd
  boot.initrd.systemd.services.rollback = {
    description = "Rollback BTRFS root subvolume to a pristine state";

    # See: man bootup
    ##################
    # initrd-root-device.target
    # ...
    # <we run here>
    # ...
    # sysroot.mount
    # initrd-root-fs.target <- if our service fails it will be detected here and the boot will fail
    requires = [ "initrd-root-device.target" ];
    after = [ "local-fs-pre.target" "initrd-root-device.target" ];
    requiredBy = [ "initrd-root-fs.target" ];
    before = [ "sysroot.mount" ];

    unitConfig = {
      AssertPathExists = "/etc/initrd-release"; # man bootup | grep /etc/initrd-release
      DefaultDependencies = false;
    };

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      BTRFS_VOL="${config.system.devices.luksMappedDevice}"
      MOUNTDIR=/rollback
      mkdir -p ''${MOUNTDIR}

      mount -t btrfs -o subvol=/ ''${BTRFS_VOL} ''${MOUNTDIR}
      ROOT_SUBVOL="''${MOUNTDIR}/root"
      # must match the snapshot name in disks.nix
      BLANK_ROOT_SNAPSHOT="''${MOUNTDIR}/root-blank"

      # TODO: investigate this further...
      # While we're tempted to just delete /root and create
      # a new snapshot from /root-blank, /root is already
      # populated at this point with a number of subvolumes,
      # which makes `btrfs subvolume delete` fail.
      # So, we remove them first.
      btrfs subvolume list -o ''${ROOT_SUBVOL} |
        cut -f9 -d' ' |
        while read -r subvolume;
        do
          echo "deleting /$subvolume subvolume..."
          btrfs subvolume delete "''${MOUNTDIR}/$subvolume"
        done &&
        echo "deleting /root subvolume..." &&
        btrfs subvolume delete ''${ROOT_SUBVOL}

      echo "restoring blank /root subvolume..."
      btrfs subvolume snapshot ''${BLANK_ROOT_SNAPSHOT} ''${ROOT_SUBVOL}

      umount ''${MOUNTDIR}
      rmdir ''${MOUNTDIR}
    '';
  };
}