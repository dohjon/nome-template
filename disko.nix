{
  disko.devices = {
    disk = {
      nvme0n1 = {
        type = "disk";
        device = "/dev/nvme0n1";
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
                name = "crypted";
                #passwordFile = "/tmp/secret.key"; # Interactive
                settings.allowDiscards = true; # less secure, For SSDs, allowing discards can improve performance and wear leveling
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];  # Override existing partition
                  postCreateHook = ''
                    TMPDIR=$(mktemp -d)
                    mount "/dev/mapper/pool-root" "$TMPDIR" -o subvol=/
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
  };
}
