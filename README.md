# README

## Prerequisite

Insert live usb (minimal iso)

Switch to root

```console
sudo -i
```

Setup wifi

```console
systemctl start wpa_supplicant
# start interactive mode
wpa_cli
> add_network
0
> set_network 0 ssid "myhomenetwork"
OK
> set_network 0 psk "mypassword"
OK
> set_network 0 key_mgmt SAE
OK
> enable_network 0
OK
...
> quit
curl googel.com
```

Find **Block Device**

In this example `/dev/nvme0n1`

```console
lsblk
> NAME   MAJ:MIN   RM   SIZE   RO   TYPE   MOUNTPOINTS
...
nvme0n1  259:0     0    932G   0    disk
...
```



## Disko install (with flake and existing disko config)

Download standalone disko configuration

```console
# Format: sudo nix run 'github:nix-community/disko#disko-install' -- --flake <flake-url>#<flake-attr> --disk <disk-name> <disk-device>
sudo nix run --experimental-features "nix-command flakes" 'github:nix-community/disko#disko-install' -- --write-efi-boot-entries --flake 'github:dohjon/nome-template#void' --disk nvme0n1 /dev/nvme0n1

# You can specify commit by doing
# 'github:dohjon/nome-template/e992516#void'
```



## disko

Download standalone disko configuration

```console
curl https://raw.githubusercontent.com/dohjon/nome-template/main/disko.nix -o /tmp/disk.nix
```

edit the `device` value according to your disk.

```console
vim /tmp/disk.nix
{
  ...
  device = "/dev/nvme0n1";
  ...
}
```

SKIP: set the disk encryption password

```console
echo -n "password" > /tmp/secret.key
```

Run disko:

```console
lsblk
blkid
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko /tmp/disk.nix
# https://wiki.archlinux.org/title/Parted#Alignment
parted --list
parted /dev/nvme0n1 -- align-check optimal 1 # check boot
parted /dev/nvme0n1 -- align-check optimal 2 # check root
```

## Enroll/setup FIDO2 with LUKS

```console
# Setup/Enroll FIDO2 with LUKS
# - https://nixos.org/manual/nixos/stable/#sec-luks-file-systems
# - https://nixos.org/manual/nixos/stable/#sec-luks-file-systems-fido2
cryptsetup status /dev/disk/by-label/ROOT # "is active" indicate it is open/unencrypted
cryptsetup luksDump /dev/nvme0n1p2 # show info luks header and key slots used
# plug in yubikey and make sure volume is unecrypted
# it will first prompt for passphrase
# followed by FIDO2 pin
# finally you need to touch yubikey when it blinks
systemd-cryptenroll --fido2-device=auto /dev/nvme0n1p2 # note we are referencing the underlying block device
# finally we generate a recovery key
# write down and store in a safe physical location
systemd-cryptenroll --recovery-key /dev/nvme0n1p2
# at last we will remove our default passphrase, beacuse we have the recovery key now.
# enter passphrase for the key you want to remove
cryptsetup luksRemoveKey /dev/nvme0n1p2 # you can also use "cryptsetup luksKillSlot /dev/nvme0n1p2 0"
# Run below command and you can verify keyslot 1 (fido2) and 2 (recovery-key) are the only keyslots used/available
cryptsetup luksDump /dev/nvme0n1p2
# TODO: backup luks header to persist (either encrypted or unencrypted)
#
```

## Install

```console
su root
mkdir -p /mnt/etc
cd /mnt/etc
git clone https://github.com/dohjon/nome-template nome
cd nome
```


then install

```console
nixos-install --flake .#nixos
```


## Update firmware

TODO> see hardware module for framework 13 amd 7040