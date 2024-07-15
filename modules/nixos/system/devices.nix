{ lib, ... }:

{

  options.system.devices = {
    rootDisk = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Disk device path to use for root filesystem.
      '';
    };

    luksMappedDevice = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        When the encrypted partition is opened, 
        cryptsetup uses the device-mapper to create a new virtual block device. 
        This new device is what you will use to interact with the decrypted data.
      '';
    };
  };
  
}