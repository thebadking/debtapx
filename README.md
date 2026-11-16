# debtapx

**debtap extended** — install `.deb` apps on Arch Linux with one command.

Wraps [debtap](https://github.com/helixarch/debtap) with:

- quiet convert → `pacman -U`
- Downloads-folder app profiles (`debtapx grok-bot`)
- Arch metadata sanitizing (drops bogus deps like bare `gtk`)
- known app fixes (e.g. Grok Bot launcher symlink, LM Studio extract path)

Prefer official repos / AUR / Flatpak when they exist. debtapx is for closed-source or Debian-only desktop apps.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/thebadking/debtapx/main/install.sh | bash
```

Installs to `~/.local/bin/debtapx` (override with `DEBTAPX_BIN_DIR`).

System-wide:

```bash
curl -fsSL https://raw.githubusercontent.com/thebadking/debtapx/main/install.sh | DEBTAPX_SYSTEM=1 bash
```

### Dependencies

```bash
yay -S debtap   # also needs pacman, sudo, bsdtar/curl for some profiles
sudo debtap -u  # once (debtapx can run this for you)
```

## Usage

```bash
debtapx --help
debtapx                          # pick a .deb from ~/Downloads
debtapx grok-bot                 # latest grok-bot_*.deb in ~/Downloads
debtapx bitwig
debtapx lm-studio                # extract installer (not debtap)
debtapx /path/to/app.deb         # generalist path
debtapx --convert-only app.deb   # convert only
debtapx --no-update app.deb      # skip debtap -u
```

### Known app profiles

| App | Method | Deb glob |
|-----|--------|----------|
| `grok-bot` / `grok` | debtap + launcher fix | `grok-bot_*.deb` |
| `bitwig` / `bitwig-studio` | debtap | `bitwig-studio*.deb` |
| `lm-studio` / `lmstudio` | extract to `/opt` | `LM-Studio-*.deb` |
| `opencode` | debtap | `opencode*.deb` |
| `autenticacao-gov` | debtap | `plugin-autenticacao-gov*.deb` |

Unknown debs use the generalist debtap path.

## How it works

1. Resolve a `.deb` (path, app name, or interactive picker in `~/Downloads`)
2. Run `debtap -Q` (after optional `debtap -u` + pkgfile compat marker)
3. Sanitize `.PKGINFO` (remove non-Arch depends)
4. `sudo pacman -U` the generated `.pkg.tar.zst`
5. Apply profile post-fixes when needed

## License

MIT — see [LICENSE](LICENSE).

debtap itself is GPL-2.0; debtapx shells out to it and does not vendor it.
