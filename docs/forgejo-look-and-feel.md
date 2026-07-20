# Forgejo look and feel

Operations notes for changing the declarative branding of
`https://git.martonaronvarga.dev`.

## Current branding

The NixOS Forgejo config sets the current branding:

- App name: `Marton A. Varga`
- Slogan: `Personal software forge`
- Default theme: `marton`
- Footer version and template timing hidden
- User email display disabled
- Custom homepage at `/`
- Public Explore browsing for public repositories
- New repositories still default to private

Those settings live in `hosts/dusk/services/forgejo.nix` under
`services.forgejo.settings`.

## Declarative source

The source files live in the flake:

```text
assets/forgejo/snowflake.jpg
assets/forgejo/home.tmpl
assets/forgejo/theme-marton.css
```

`hosts/dusk/services/forgejo.nix` builds the source image into Forgejo-ready
assets and installs them during `forgejo.service` startup.

Generated runtime files:

```text
/var/lib/forgejo/custom/public/assets/img/mav-snowflake.png
/var/lib/forgejo/custom/public/assets/img/logo.svg
/var/lib/forgejo/custom/public/assets/img/favicon.svg
/var/lib/forgejo/custom/public/assets/img/favicon.png
/var/lib/forgejo/custom/public/assets/img/apple-touch-icon.png
/var/lib/forgejo/custom/public/assets/css/theme-marton.css
/var/lib/forgejo/custom/templates/home.tmpl
```

Do not reference `~/pictures/snowflake.jpg` from the service. Copy replacement
assets into the flake and let Nix build the runtime outputs.

## Runtime path

Forgejo reads custom templates and public assets from:

```text
/var/lib/forgejo/custom
```

Ownership must be:

```sh
sudo chown -R forgejo:forgejo /var/lib/forgejo/custom
```

Runtime files are overwritten from the flake when `forgejo.service` starts.
Restart after asset/template changes:

```sh
sudo systemctl restart forgejo
```

## Logo replacement

Replace `assets/forgejo/snowflake.jpg` with a square image, then rebuild and
deploy `dusk`. A 1024x1024 source is enough.

A practical logo should:

- have a transparent background;
- work at 32px and 128px;
- avoid thin lines that disappear in dark mode;
- use one or two colors at most;
- not rely on external fonts.

The build derives the navbar logo, favicon, Apple touch icon, and landing-page
image from that source.

## Theme CSS

Edit:

```text
assets/forgejo/theme-marton.css
```

The theme is registered in `ui.THEMES` and selected by
`ui.DEFAULT_THEME = "marton"`.

Avoid heavy CSS overrides. Forgejo upgrades can change DOM structure.

## Homepage

Edit:

```text
assets/forgejo/home.tmpl
```

The root page uses `server.LANDING_PAGE = "home"`. Keep the override narrow:
only the landing page is customized, while repository, Explore, sign-in, and
admin pages remain upstream Forgejo templates.

## Quick checks

After any look-and-feel change:

```sh
curl -fsSI https://git.martonaronvarga.dev/
ssh usu@10.200.200.2 \
  'systemctl is-active forgejo && journalctl -u forgejo -n 40 --no-pager'
```

Open these pages manually:

- `https://git.martonaronvarga.dev/`
- `https://git.martonaronvarga.dev/explore/repos`
- `https://git.martonaronvarga.dev/user/login`
- one repository page;
- one file view with code;
- mobile viewport for the header.
