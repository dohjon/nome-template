{ config, lib, pkgs, ... }:

{
  disko.devices = {
    disk.${lib.removePrefix "/dev/" config.system.devices.rootDisk} = {
      type = "disk";
      device = "${config.system.devices.rootDisk}";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            type = "EF00";
            start = "1MiB";
            end = "1GiB";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "${lib.removePrefix "/dev/mapper/" config.system.devices.luksMappedDevice}";
              settings.allowDiscards = true; # less secure, For SSDs, allowing discards can improve performance and wear leveling
              content = {
                type = "btrfs";
                #extraArgs = [ "-f" ];  # Override existing partition
                postCreateHook = ''
                  TMPDIR=$(mktemp -d)
                  #mount "${config.system.devices.luksMappedDevice}" "$TMPDIR" -o subvol=/
                  mount /dev/mapper/crypted "$TMPDIR" -o subvol=/
                  trap 'umount $TMPDIR; rm -rf $TMPDIR' EXIT
                  # Create snapshot of the empty volume root
                  btrfs subvolume snapshot -r $TMPDIR/root $TMPDIR/root-blank
                '';
                subvolumes = {
                  "/root" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/persist" = {
                    mountpoint = "/persist";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "/state" = {
                    mountpoint = "/state";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  fileSystems."/state".neededForBoot = true;
  fileSystems."/persist".neededForBoot = true;
}
