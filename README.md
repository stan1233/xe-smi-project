# xe-smi

**A lightweight GPU monitoring tool for Intel Arc GPUs running under the `xe` kernel driver in SR-IOV Virtual Function (VF) mode.**

Think of it as `nvidia-smi` / `nvitop` for Intel Arc — especially useful in virtualized environments (Proxmox, QEMU/KVM) where tools like `xpu-smi`, `intel_gpu_top`, and `nvtop` fail to detect SR-IOV VF devices.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Shell](https://img.shields.io/badge/shell-bash-green.svg)
![Platform](https://img.shields.io/badge/platform-Linux-lightgrey.svg)

## The Problem

If you're running an Intel Arc Pro B50 (or other Battlemage GPU) passed through as an SR-IOV Virtual Function to a VM, you'll quickly discover:

- **`intel_gpu_top`** — only supports the `i915` driver, not `xe`
- **`nvtop`** — reports "No GPU to monitor"
- **`xpu-smi`** — reports "No device discovered" (Level Zero doesn't recognize VF devices)
- **`nvidia-smi`** — obviously not for Intel GPUs

`xe-smi` solves this by reading directly from Linux `debugfs` and `sysfs`, which work correctly even in SR-IOV VF mode.

## Features

- **Live monitoring mode** (default) — real-time dashboard with VRAM history graph, like `nvitop`
- **Static snapshot mode** (`-s`) — one-time output, like `nvidia-smi`
- **VRAM usage** — real-time used/total/free with color-coded progress bar
- **VRAM history graph** — scrolling ASCII chart showing usage over time
- **GPU process list** — shows processes using the GPU with VRAM and RSS
- **GPU topology** — DSS count, EU count per GT
- **Engine list** — available engines (compute, render, copy, video, etc.)
- **GT activity stats** — TLB invalidations and page faults (delta per interval)
- **Color-coded output** — green/yellow/red thresholds for usage levels
- **Zero dependencies** — pure bash, reads kernel interfaces directly

## Screenshots

### Live Mode (default)
```
+──────────────────────────────────────────────────────────────────────────+
 xe-smi LIVE  11:09:05  refresh: 1s            Ctrl+C to exit
+──────────────────────────────────────────────────────────────────────────+
 GPU 0: Intel Arc Pro B50 (Battlemage G21)
 Mode: SR-IOV VF  PCI: 0000:00:10.0  Topo: GT0: 16DSS×8EU=128 | GT1: 8DSS×8EU=64
+──────────────────────────────────────────────────────────────────────────+
 VRAM  ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  128/1346 MiB (9%)

 VRAM History:
 100%│
     │
  50%│
     │
     │
     │
     │██████████████████████████████
   0%│──────────────────────────────────────────────────
                                                  now →
+──────────────────────────────────────────────────────────────────────────+
 Processes:
  PID     COMMAND            VRAM(KB)    RSS(KB)
  1234    ollama             102400      524288
+──────────────────────────────────────────────────────────────────────────+
 Activity (delta/1s):
  GT0: TLB±3 faults±0  |  GT1: TLB±1 faults±0
  Engines: bcs ccs rcs vcs vecs
+──────────────────────────────────────────────────────────────────────────+
```

### Static Mode (`-s`)
```
+──────────────────────────────────────────────────────────────────────────+
 xe-smi  Sun Mar 01 11:10:19 2026    Driver: xe (SR-IOV VF)
+──────────────────────────────────────────────────────────────────────────+
 GPU 0: Intel Arc Pro B50 (Battlemage G21)
 Mode: SR-IOV VF    PCI: 0000:00:10.0
+──────────────────────────────────────────────────────────────────────────+
 VRAM:  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  2 MiB / 1346 MiB  (0%)
 Free: 1344 MiB
+──────────────────────────────────────────────────────────────────────────+
 Topology: GT0: 16DSS×8EU=128 | GT1: 8DSS×8EU=64
 Engines:  bcs ccs rcs vcs vecs
+──────────────────────────────────────────────────────────────────────────+
 GPU Processes:
  No GPU processes running
+──────────────────────────────────────────────────────────────────────────+
```

## Installation

```bash
# Clone the repo
git clone https://github.com/stan1233/xe-smi-project.git
cd xe-smi

# Install
sudo install -m 755 xe-smi /usr/local/bin/xe-smi
```

Or one-liner:

```bash
sudo curl -fsSL https://raw.githubusercontent.com/stan1233/xe-smi-project/main/xe-smi -o /usr/local/bin/xe-smi && sudo chmod +x /usr/local/bin/xe-smi
```

## Usage

```
xe-smi — Intel Arc GPU Monitor (SR-IOV VF)

Usage: xe-smi [OPTIONS]

Options:
  (default)     Live dynamic monitoring (like nvitop)
  -s            Static snapshot (like nvidia-smi)
  -i SECONDS    Refresh interval for live mode (default: 1)
  -h            Show this help

Examples:
  sudo xe-smi           # Live monitoring
  sudo xe-smi -s        # One-time snapshot
  sudo xe-smi -i 2      # Live monitoring, refresh every 2s
```

> **Note:** `sudo` is required because the tool reads from `/sys/kernel/debug/` which is only accessible to root.

## Requirements

- **Linux** with kernel 6.17+ (for `xe` driver SR-IOV VF support)
- **Intel Arc GPU** using the `xe` kernel driver
- **bash** 4.0+
- **bc** (for topology bit counting, usually pre-installed)
- Root access (for debugfs)

### Tested On

| GPU | Mode | Kernel | Distro | Status |
|-----|------|--------|--------|--------|
| Intel Arc Pro B50 (Battlemage G21) | SR-IOV VF | 6.19.0 | Ubuntu 24.04 | ✅ |

## How It Works

Since standard GPU monitoring tools don't work with Intel `xe` driver in SR-IOV VF mode, `xe-smi` reads data directly from kernel interfaces:

| Data | Source |
|------|--------|
| VRAM usage | `/sys/kernel/debug/dri/*/vram0_mm` |
| Device info | `/sys/kernel/debug/dri/*/info` |
| SR-IOV status | `/sys/kernel/debug/dri/*/sriov_info` |
| GPU topology | `/sys/kernel/debug/dri/*/gt{0,1}/topology` |
| GT statistics | `/sys/kernel/debug/dri/*/gt{0,1}/stats` |
| GPU processes | `/proc/*/fdinfo/*` (DRM fdinfo) |
| Engine list | `/sys/class/drm/card*/device/tile0/gt*/engines/` |

### What's NOT available in VF mode

Due to SR-IOV architecture, the following are controlled by the host (Physical Function) and are **not accessible** from inside the VM:

- GPU temperature
- GPU clock frequency
- Power consumption
- Fan speed
- GPU utilization percentage (engine busy %)

These can only be monitored from the hypervisor host.

## Configuration

By default, `xe-smi` looks at `/sys/kernel/debug/dri/1` and `/sys/class/drm/card1`. If your GPU is on a different DRI index, edit the two variables at the top of the script:

```bash
DRI_DEBUG="/sys/kernel/debug/dri/1"
DRI_SYS="/sys/class/drm/card1/device"
```

To find your GPU's index:

```bash
ls -la /sys/class/drm/card*/device/driver
# Look for the one using the 'xe' driver
```

## Kernel Setup (if needed)

If your kernel doesn't have `xe` VF support, see the [Intel Arc Pro B50 Linux Setup Guide](https://gist.github.com/Bortus-AI/c9a79371b561c716874ba2cc2bd2f3cf) for instructions on:

1. Installing kernel 6.19+ (for `xe` VF support)
2. Installing Battlemage GPU firmware
3. Verifying driver binding

## Contributing

Contributions are welcome! Some ideas:

- [ ] Auto-detect DRI card index
- [ ] Support for multiple GPUs
- [ ] Support for PF (Physical Function) mode with frequency/temperature
- [ ] JSON output mode for scripting
- [ ] Support for other Intel Arc GPUs (Alchemist, etc.)
- [ ] Systemd service for logging GPU stats

## License

MIT License — see [LICENSE](LICENSE) for details.

## Acknowledgments

- [Bortus-AI's B50 Linux Setup Guide](https://gist.github.com/Bortus-AI/c9a79371b561c716874ba2cc2bd2f3cf)
- [Level1Techs Proxmox + Intel B50 SR-IOV Guide](https://forum.level1techs.com/t/proxmox-9-0-intel-b50-sr-iov-finally-its-almost-here-early-adopters-guide/238107)
- The Linux `xe` kernel driver developers
