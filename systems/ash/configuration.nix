{ config, pkgs, ... }:
{
  networking.hostName = "ash";
  networking.useDHCP = false;

  systemd.network = {
    enable = true;
    networks."10-lan" = {
      matchConfig.Name = "ens* enp* eth*";
      networkConfig.DHCP = "ipv4";
    };
  };

  services.qemuGuest.enable = true;

  nixpkgs.config.allowUnfree = true;
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    nvidiaSettings = false;
    nvidiaPersistenced = false;

    # NixOS's finegrained option requires PRIME offload; this GPU is headless.
    moduleParams.nvidia.NVreg_DynamicPowerManagement = "0x02";
  };

  # All GPU PCI functions must permit runtime suspend, including HDMI audio.
  services.udev.extraRules = ''
    ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", TEST=="power/control", ATTR{power/control}="auto"
    ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", TEST=="power/control", ATTR{power/control}="on"
  '';

  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
    host = "0.0.0.0";
    loadModels = [ "qwen3:4b-instruct" ];
    environmentVariables.OLLAMA_KEEP_ALIVE = "1m";
  };
}
