# Helium Flatpak

This folder contains a Flatpak manifest to package the latest prebuilt [Helium Browser](https://github.com/imputnet/helium) binary
from the official [GitHub releases](https://github.com/imputnet/helium-linux/releases).
This fork enables pre-release support.

## Build and Install

You can build and install the Flatpak locally:

```bash
flatpak-builder --user --install --force-clean build-dir com.imputnet.Helium.yml
flatpak run com.imputnet.Helium
```

## Install from repo
Alternatively, you can install Helium directly from the Flatpak repository:

```bash
flatpak remote-add --user --no-gpg-verify helium-repo https://aniruddhgutta.github.io/helium-flatpak
flatpak install helium-repo com.imputnet.Helium
flatpak run com.imputnet.Helium
```
