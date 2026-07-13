# Changelog

All notable infrastructure changes are recorded here.

## [unreleased]


### Deployment

- Deploy(dusk): manage host through gloam wireguard


### Documentation

- Docs: update changelog

- Docs: update changelog

- Docs: update changelog

- Docs(dusk): document install and operations

- Docs: update changelog

- Docs: update changelog


### Features

- Feat(dusk): customize forgejo homepage

- Feat(dusk): host forgejo on git subdomain

- Feat(hosts): harden edge hosts and enable shade secure boot

- Feat(dusk): serve domain placeholder through gloam

- Feat(modules): Fall back to home-manager aerc module

- Feat(modules): manage GMail OAuth tokens with oama

Replace the agenix-managed Gmail refresh token flow with oama-backed OAuth
credential management. aerc now receives short-lived access tokens via
credential commands, while oama owns refresh, renewal, and reauthorization
state.

Remove token_endpoint, client_id, and client_secret from the aerc account URI
so aerc treats source-cred-cmd and outgoing-cred-cmd output as access tokens.
Keep agenix only for stable OAuth client credentials.

Add wrapper commands for token lookup, preflight checking, and interactive
reauthorization. Add a user systemd timer to periodically check token validity
and surface invalid_grant failures before opening aerc.

Persist oama and GPG state for impermanent systems so OAuth credentials survive
relogin and reboot.

- Feat(home): persist firefox session and state

- Feat(home): add monochrome yazi theme

- Feat(hosts): add gloam inventory and profiles


### Fixes

- Fix(home): yazi theming

- Fix(home): stop projects dir and whiten yazi folders

- Fix(modules): Yazi and Waybar theme style improvement

- Fix(modules): monochrome yazi and ephemereal .zotero

- Fix(config): derive flake paths from config

- Fix(hosts): harden shade rollback initrd

- Fix(hyprland): update rules for current syntax


### Home Manager

- Home(git): configure default branch and workflow

- Home(git): add forge remote shortcuts

- Home(waybar): speed up critical battery blink

- Home(aerc): update gmail account integration

- Home(gpg): move agent setup to home manager

- Home: align desktop state and terminal tools

- Home(theme): add black metal terminal themes


### Hosts

- Host(shade): add guarded home rollback


### Maintenance

- Chore(recovery): restore latest flake work

- Chore(home): update desktop and terminal config


### Modules and Architecture

- Module(nixos): clean up base networking modules


### Networking

- Network(dusk): persist wireguard key material


### Refactors

- Refactor(hosts): modularize flake infrastructure


### Secrets and Identity

- Secret(oci): manage shade credentials with agenix

- Secret(shade): move user password hash to agenix
