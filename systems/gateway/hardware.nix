{ lib, ... }:
{
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  boot.initrd.availableKernelModules = [
    "ahci"
    "xhci_pci"
    "ehci_pci"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [
    "bonding"
    "8021q"
    "wireguard"
    "ifb"
    "sch_cake"
  ];
  # Installation contract: create these labels on the NEW NixOS disk.
  # These deliberately do not point at VyOS's persistence partition.
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
    options = [ "umask=0077" ];
  };
}
