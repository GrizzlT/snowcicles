# Snowcicles - modular templates for Nix(OS)

This repo is my latest attempt at keeping my code
[DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself). Instead of having
a bunch of different machine configurations around and sharing a lot of config
in each configuration once, I'll now use this repo for any common pieces of
code I use more than once. More readme will follow with updates.

## Nixos configurations

Defaults assumed in this repo:

- `hostPlatform` = `x86_64-linux`
- `agenix` is enabled (includes the [agenix](https://github.com/ryantm/agenix)
  nixosModule)
- `generators`: all formats listed on
  [nixos-generators](https://github.com/nix-community/nixos-generators) are
  included and buildable

## Home manager configurations

Defaults assumed in this repo:

- `system` = `x86_64-linux` (but this shouldn't really matter since hosts
  should be specified explicitly)
