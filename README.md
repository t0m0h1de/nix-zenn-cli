# nix-zenn-cli

Up-to-date [zenn-cli](https://github.com/zenn-dev/zenn-editor) package for Nix users.

## Why?
The `zenn-cli` version in `nixpkgs` often lags behind the latest release. This repository provides a Nix Flake that tracks the latest npm version and provides pre-built binaries via CI.
The packaging approach is based on the `zenn-cli` derivation in `nixpkgs` (with adjustments for this flake): https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/ze/zenn-cli/package.nix

## Usage

### 1. Add to your `flake.nix`
```nix
{
  inputs.nix-zenn-cli.url = "github:t0m0h1de/nix-zenn-cli";
}
```

### 2. Include in Home Manager or System Packages
```nix
{ inputs, pkgs, ... }: {
  home.packages = [
    inputs.nix-zenn-cli.packages.${pkgs.system}.default
  ];
}
```

## License
MIT (c) 2026 Tomohide Sawada
