{ config, lib, pkgs, inputs, ... }:

{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  environment.systemPackages = with pkgs; [
    (import ../../modules/scripts/fs-diff.nix { inherit pkgs config; })
  ];

  # /persist is the location you plan to store the files
  environment.persistence."/persist" = {
    # Hide these mount from the sidebar of file managers
    hideMounts = true;

    # Folders you want to map
    directories = [
      "/etc/nixos" # Optional if using flakes and flake is stored somewhere else like home directory
      "/var/lib/nixos" # contains important state: https://github.com/nix-community/impermanence/issues/178
      "/var/lib/systemd/coredump"
      #"/var/lib/systemd" # TODO: investigate if this is better then singling out services, alot of people seem to persist this
      "/var/log"
      "/var/db/sudo/lectured" # TODO: should this be chmod 700?
      "/etc/NetworkManager/system-connections" # TODO: store in keyring, passwords currently stored in plaintext
      # Unfortunately it isn't possible to persist individual state folders for
      # services using DynamicUser=yes. This is because systemd assigns
      # dynamic UIDs to users of this service so it's impossible to set the
      # required permissions with impermanence. Services place this dynamic
      # user folder in /var/lib/private/<service>. I will add commented out
      # persistence definitions in the relevant services so their files are
      # still documented.
      # TODO: investigate this further...
      # {
      #   directory = "/var/lib/private";
      #   mode = "0700";
      # }
    ];

    # Files you want to map
    files = [
      # machine-id is used by systemd for the journal, if you don't persist this
      # file you won't be able to easily use journalctl to look at journals for
      # previous boots.
      "/etc/machine-id"
      #"/var/lib/logrotate.status" # TODO: investigate this further...
      # "/etc/adjtime" # TODO: investigate this further...
      # TODO: need to persist /home/dohjon/nixos
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
      BTRFS_VOL="${config.profile.luksMappedDevice}"
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