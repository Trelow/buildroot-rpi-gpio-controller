# Buildroot GPIO Web Controller

Minimal embedded Linux IoT project for an emulated **Raspberry Pi 3 Model B**, built with **Buildroot** and a custom **ARM64 Linux kernel**.

The system boots in **QEMU**, starts network services automatically, exposes a lightweight **web interface** for LED control, and drives virtual GPIO-based Christmas lights through a background daemon.

## Web Interface

The application provides a simple Christmas tree control panel with 20 LEDs.

Supported actions:

- click an LED to toggle it on or off
- Start to begin blinking animation for active LEDs
- Stop to stop the animation
- Random to enable a random LED pattern
- All On to turn on all LEDs
- All Off to turn off all LEDs

## Build Details

### Root Filesystem

The root filesystem was generated using **Buildroot 2025.02.9**.

The Buildroot configuration includes the packages and options required for:

- BusyBox userland
- Dropbear SSH server
- networking support and DHCP
- HTTP serving through BusyBox httpd
- GPIO control through libgpiod
- a bootable ext4 root filesystem image

The final root filesystem was kept lightweight while still supporting remote access, a web UI, and GPIO control services.

### Kernel

The kernel is based on **Linux 6.12.64**, compiled manually for `ARCH=arm64`.

Kernel-related notes:

- custom `LOCALVERSION` was set
- `LOCALVERSION_AUTO` was disabled
- `CONFIG_DEBUG_INFO` was disabled to reduce kernel size
- the device tree used is `bcm2837-rpi-3-b.dtb`

The kernel was prepared specifically for a Raspberry Pi 3 Model B environment running in QEMU.

## Image Layout

The project uses:

- a bootable SD card image: `tema2.img`
- a compressed kernel image: `vmlinuz-tema2`
- the Raspberry Pi 3 device tree: `bcm2837-rpi-3-b.dtb`

The runtime image boots the root filesystem from:

- `/dev/mmcblk0p2`

## Overlay-Based Customization

Instead of modifying the generated root filesystem manually after each build, the project uses an overlay directory to inject custom files into the final image.

The overlay contains:

- boot scripts in `overlay/etc/init.d/`
- service logic in `overlay/srv/`
- web assets and CGI endpoints in `overlay/www/`

This makes the system easier to maintain and reproduce.

## Boot-Time Services

At boot, the system starts the following components automatically:

- Dropbear on port 22
- BusyBox httpd on port 80
- the custom GPIO daemon

The project uses SysV init scripts to start the services in the correct order.

## Networking

The guest system is configured to:

- use interface `eth0`
- obtain its IP address through DHCP
- expose SSH and HTTP to the host through QEMU port forwarding

Forwarded host ports:

- `localhost:5555` → guest 22
- `localhost:8888` → guest 80

## Quick Start

Open two terminals.

### Terminal 1

```bash
make gpio_viewer
```

### Terminal 2

```bash
make run
```

Then open the web interface in your browser:

- http://localhost:8888/

Optional SSH access:

```bash
ssh root@localhost -p 5555
```

Default credentials:

- user: `root`
- password: `tema2025`

## Build and Run

The provided `Makefile` includes helper targets for running QEMU, starting the GPIO viewer, and generating the submission archives.

### Available Targets

```bash
make run
make gpio_viewer
make bin_archive
make checksum
make source_archive
make clean
```

### Run the Project

Start the GPIO viewer in one terminal:

```bash
make gpio_viewer
```

Then start the virtual machine in another terminal:

```bash
make run
```

This runs:

- `gpio-viewer.py` for monitoring GPIO state through QEMU qtest
- `launch-tema2.sh` for booting the Raspberry Pi 3 image in QEMU

### Access the Services from the Host

After boot:

- Web UI: http://localhost:8888/
- SSH: `ssh root@localhost -p 5555`

Default credentials:

- user: `root`
- password: `tema2025`

### Run QEMU Without the GPIO Viewer

If you want to boot the VM without qtest support:

```bash
make run A=--no-qtest
```

You can also disable networking:

```bash
make run A=--no-net
```

### Pass Custom Arguments to the Launcher

The `Makefile` forwards the `A` variable to `launch-tema2.sh`.

Examples:

```bash
make run A=--no-qtest
make run A=--no-net
make run A=--serial1
```

### Run the Scripts Directly

Instead of using `make`, you can also run the scripts manually.

Start the GPIO viewer:

```bash
python3 gpio-viewer.py
```

Start QEMU:

```bash
./launch-tema2.sh
```

## Create the Binary Archive

Generate the binary archive used for submission:

```bash
make bin_archive
```

This creates:

- `bin_archive.tar.xz`

containing:

- `tema2.img`
- `vmlinuz-tema2`
- `bcm2837-rpi-3-b.dtb`
- `launch-tema2.sh`

## Generate Checksum

```bash
make checksum
```

This creates:

- `checksum.txt`

## Create the Source Archive

```bash
make source_archive
```

This creates:

- `source_archive.zip`

while excluding generated artifacts and large binary files according to the ignore list from the `Makefile`.

## Clean Generated Archives

```bash
make clean
```

This removes:

- `bin_archive.tar.xz`
- `source_archive.zip`

## Reproducing the Build

This repository mainly contains the project sources, configuration files, overlay, and helper scripts.

The final generated runtime artifacts are:

- `tema2.img`
- `vmlinuz-tema2`
- `bcm2837-rpi-3-b.dtb`

A typical build workflow is:

- prepare the Linux kernel source and configure it for arm64
- compile the kernel image and device tree
- configure Buildroot using `buildroot_config`
- apply the project overlay
- generate the root filesystem image
- place the generated artifacts next to `launch-tema2.sh`
- boot the system with QEMU

Depending on your setup, the exact kernel and Buildroot build commands may differ, but the repository contains the configuration and runtime scripts required to reproduce the final system layout.

## Accessing the System

The QEMU launch script forwards these host ports:

- SSH: localhost:5555 -> guest port 22
- HTTP: localhost:8888 -> guest port 80

Inside the guest, the main interface is `eth0`, configured through DHCP.

Default system configuration:

- hostname: `tema2025`
- root password: `tema2025`
- network interface: `eth0`
- IP configuration: DHCP
- root filesystem device: `mmcblk0p2`

## Testing

Useful checks inside the VM:

```bash
uname -a
hostname
ip a
ls -l /dev/gpiochip*
ps aux
ss -ltnp
```

Useful checks from the host:

```bash
curl http://localhost:8888/
ssh root@localhost -p 5555
```

To validate GPIO functionality:

- start `gpio-viewer.py`
- boot the VM
- open the web UI
- trigger LED actions from the browser
- observe GPIO state changes in the viewer

## Notes

- The project uses SysV init for boot-time services.
- The HTTP backend is implemented through CGI, keeping the solution lightweight.
- GPIO control is handled through libgpiod tools, mainly `gpioset`.
- The design focuses on simplicity, reproducibility, and a small runtime footprint.
