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

## Create snapshot of empty the empty volume root

```console
btrfs subvolume snapshot -r /mnt/root /mnt/root-blank
```

## Enroll/setup FIDO2 with LUKS

```console
btrfs subvolume snapshot -r /mnt/root /mnt/root-blank
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
