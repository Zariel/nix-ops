# Ash

`ash` is a headless QEMU VM that serves `qwen3:4b-instruct` through CUDA-enabled
Ollama using a passed-through RTX A2000. It inherits the base and server
roles, including SSH access for `chris` and Vector logging.

## Provision the VM

1. Create an x86-64 VM with UEFI firmware and pass through the RTX A2000
   from the hypervisor. GPU passthrough must be configured on the hypervisor
   before the guest can use the card.
2. Boot a Linux live environment with SSH access as root, or as a user with
   passwordless sudo. A NixOS installer ISO avoids needing to kexec into an
   installer. Identify the VM's disk with `lsblk -o NAME,SIZE,TYPE,MODEL,SERIAL`
   and confirm that `/dev/sda` is the intended install disk.
3. Reserve `10.1.1.55` outside the DHCP pool and add a DNS record for
   `ash.cbannister.casa`. The guest uses `10.1.1.55/24`, gateway `10.1.1.1`,
   and DNS server `172.53.53.53`. The deployment address is `10.1.1.55`.
   The network configuration matches `ens*`, `enp*`,
   and `eth*` interfaces.
4. From this repository on the deployment machine, build the system before
   starting installation:

   ```sh
   nix build .#nixosConfigurations.ash.config.system.build.toplevel --no-link
   ```

5. Verify the target address and selected disk. **This command erases
   `/dev/sda` on `10.1.1.55`.** Run the installation:

   ```sh
   nix develop --command nixos-anywhere --flake .#ash --target-host root@10.1.1.55 -i ~/.ssh/id_ed25519
   ```

Disko creates a GPT partition table, a 1 GiB FAT EFI partition at `/boot`, and
an ext4 root partition using the remaining disk space. Disko owns the filesystem
configuration; `hardware-configuration.nix` contains the guest's hardware scan,
generated with `nixos-generate-config --show-hardware-config --no-filesystems`.
The `chris@gaming` SSH key is authorized for `root` and `chris` after installation.

After reboot, verify SSH access as `chris` and deploy subsequent changes with:

```sh
ssh chris@10.1.1.55
nix develop --command deploy .#ash
```

See the [nixos-anywhere quickstart](https://nix-community.github.io/nixos-anywhere/quickstart.html)
for installer prerequisites and options.

Ollama listens on TCP port `11434` on all IPv4 interfaces. The server role
disables the guest firewall, so place this VM on the intended trusted network.
Model files persist in `/var/lib/ollama/models`. The NixOS model loader pulls
`qwen3:4b-instruct` after Ollama starts and retries failed downloads; allow Internet
access and disk space for the initial download.

## Verify the service

On the VM, check the GPU, download, and inference:

```sh
nvidia-smi
systemctl status ollama ollama-model-loader
ollama list
ollama run qwen3:4b-instruct 'Reply with a short greeting.'
ollama ps
```

Confirm that `nvidia-smi` lists the RTX A2000, `ollama list` includes
`qwen3:4b-instruct`, and `ollama ps` reports GPU use after inference. Repeat inference
after a reboot to verify that the driver and persisted model remain usable.

From another machine with the Ollama CLI, verify network access:

```sh
OLLAMA_HOST=http://ash.cbannister.casa:11434 ollama list
```

For GPU compatibility details, see [Ollama hardware support](https://docs.ollama.com/gpu).

## Verify idle power management

Ollama unloads models after one minute without requests, releasing the CUDA
workload. The next request reloads the model, adding startup latency. Clients
can override this timeout with the API's `keep_alive` parameter; see the
[Ollama FAQ](https://docs.ollama.com/faq#how-do-i-keep-a-model-loaded-in-memory-or-make-it-unload-immediately).

NVIDIA persistence is disabled. The driver requests runtime D3 power management,
and udev permits runtime suspend for every NVIDIA PCI function, including any
passed-through audio function. Full power-off requires hardware and ACPI
support exposed to the VM; if unavailable, the GPU uses its built-in idle
power management. See [NVIDIA runtime power management](https://download.nvidia.com/XFree86/Linux-x86_64/595.104.02/README/dynamicpowermanagement.html).

After inference, leave the service idle for more than one minute. Confirm
that `ollama ps` no longer lists the model, then inspect the driver's support
status and the kernel's runtime state:

```sh
ollama ps
for gpu in /proc/driver/nvidia/gpus/*; do
  cat "$gpu/power"
  cat "/sys/bus/pci/devices/${gpu##*/}/power/control"
  cat "/sys/bus/pci/devices/${gpu##*/}/power/runtime_status"
done
```

The control policy must be `auto`. If runtime D3 is supported through passthrough,
the kernel state should settle to `suspended`. Run inference again to verify
that the GPU resumes successfully, and repeat the idle check after a reboot.
For a snapshot of power draw and clocks, use:

```sh
nvidia-smi --query-gpu=name,persistence_mode,pstate,power.draw,clocks.gr,clocks.mem --format=csv
```

Running `nvidia-smi` accesses the GPU and can wake it, so inspect the kernel's
runtime state before querying it. Compare idle power draw with inference power
draw; do not assume a particular idle wattage before measuring the provisioned VM.
