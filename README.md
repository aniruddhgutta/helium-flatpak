# Helium Flatpak

This folder contains a Flatpak manifest to package the latest prebuilt [Helium Browser](https://github.com/imputnet/helium) binary
from the official [GitHub releases](https://github.com/imputnet/helium-linux/releases).

This fork enables pre-release support.

## Build and Install

You can build and install the Flatpak locally:

```sh
# Clone the repo
repo_dir="$HOME/.local/helium-flatpak"
git clone https://github.com/aniruddhgutta/helium-flatpak "$repo_dir"
cd "$repo_dir"

# Build flatpak
./grab_latest.sh
flatpak-builder --repo=repo --force-clean build-dir com.imputnet.Helium.yml
flatpak build-update-repo --generate-static-deltas repo

# Add local repo and install built flatpak
flatpak remote-add --if-not-exists --user --no-gpg-verify helium-local file://"$repo_dir/repo"
flatpak install helium-local com.imputnet.Helium
flatpak run com.imputnet.Helium
```

## Install from repo
Alternatively, you can install Helium directly from the Flatpak repository:

```sh
flatpak remote-add --user --no-gpg-verify helium-repo https://aniruddhgutta.github.io/helium-flatpak
flatpak install helium-repo com.imputnet.Helium
flatpak run com.imputnet.Helium
```
