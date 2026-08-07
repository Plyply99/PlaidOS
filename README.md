# PlaidOS

Fedora atomic with Gnome, Plaid and supporting apps.



<img width="3840" height="2160" alt="Screenshot From 2026-08-07 05-01-36" src="https://github.com/user-attachments/assets/bfaa2ef9-ba1c-4040-a2d8-faee6a5128b4" />




# To install:

## Option 1: Install from ISO

Download the latest installer ISO from the [Actions tab](https://github.com/Plyply99/PlaidOS/actions/workflows/build-disk.yml) (run the "Build disk images" workflow, then grab the `plaidos-anaconda-iso` artifact). Rebuilt monthly.

- **In a VM (GNOME Boxes):** drag the ISO into Boxes and install like any Fedora installer, or `flatpak run org.gnome.Boxes --import /path/to/install.iso`
- **On real hardware:** write the ISO to a USB stick (e.g. `dd if=install.iso of=/dev/sdX bs=4M status=progress`) and boot from it

The installer puts PlaidOS on your disk with Plaid, fonts, and the full reference config baked in.

## Option 2: Bootc switch (existing installs)

Download and install an atomic image such as Fedora CoreOS or Silverblue.
Then enter the command below in a terminal.

```
sudo bootc switch ghcr.io/plyply99/plaidos:latest
```

Updates are then `sudo bootc upgrade` (the image rebuilds daily).


