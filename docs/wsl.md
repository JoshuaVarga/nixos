# NixOS on WSL

The `wsl` host is device-independent: any Windows machine gets the same system
by installing NixOS-WSL, cloning this repo, and building `#wsl`.

## Choosing the account

The WSL account is whatever user `modules/hosts.nix` declares for the host:

```nix
den.hosts.x86_64-linux.wsl = {
  wsl.enable = true;
  users.joshua = { };
};
```

To use a different profile, change that entry to `users.<user> = { };` and add
`modules/<user>.nix` defining `den.aspects.<user>` with, at minimum,
`den.provides.define-user`, `den.provides.primary-user` and `den.aspects.shell`
in its `includes` (copy `modules/joshua.nix`). `primary-user` is what sets
`wsl.defaultUser`, so without it the distro keeps logging in as the stock
`nixos` account; the build fails with "wsl host user <user> is incomplete" if
the aspect is missing. `git add` the new module before rebuilding — flakes only
see tracked files.

Everything below uses `<user>` for that name.

## First install

1. In PowerShell, enable WSL and install NixOS-WSL (requires WSL >= 2.4.4):

   ```powershell
   wsl --install --no-distribution
   # download nixos.wsl from https://github.com/nix-community/NixOS-WSL/releases/latest
   wsl --install --from-file nixos.wsl
   wsl -t NixOS
   ```

2. Open a root shell — the whole bootstrap runs as root, because the stock
   `nixos` account has to go away before `<user>` can take uid 1000 (skip the
   `userdel` below if `<user>` *is* `nixos`):

   ```powershell
   wsl -d NixOS --user root
   ```

3. Inside that shell:

   ```bash
   nix-channel --update
   mkdir -p /home/<user>/git
   nix-shell -p git --run 'git clone https://github.com/JoshuaVarga/nixos.git /home/<user>/git/nixos'
   mv /etc/nixos /etc/nixos.stock
   ln -s /home/<user>/git/nixos /etc/nixos
   userdel -r nixos
   nixos-rebuild boot --flake /etc/nixos#wsl \
     --option extra-experimental-features "nix-command flakes"
   exit
   ```

   `boot`, not `switch`: the default user changes in this generation, and
   NixOS-WSL requires a restart of the distro for that to apply cleanly.

4. Back in PowerShell, cycle the distro so the new generation and the new
   default user take effect, then fix ownership of the clone:

   ```powershell
   wsl -t NixOS
   wsl -d NixOS --user root exit
   wsl -t NixOS
   wsl -d NixOS --user root -- chown -R <user>:users /home/<user>
   wsl -d NixOS
   ```

   The last command drops you in as `<user>` with nushell as the login shell.

5. Apply dotfiles (separate repo):

   ```bash
   chezmoi init --apply <dotfiles-repo>
   ```

## Day-to-day

- Rebuild: `nh os switch` (or `sudo nixos-rebuild switch --flake /etc/nixos#wsl`).
  `/etc/nixos` is the symlink to `/home/<user>/git/nixos`, same as on titan.
- Windows PATH is not merged into the WSL PATH. Call Windows programs by
  absolute path, e.g. `/mnt/c/Windows/System32/notepad.exe`.
- `xdg-open <url>` opens the URL in the Windows default browser; `$BROWSER`
  points at it, so agent login flows work.
- Clipboard goes through WSLg's X11 server (`DISPLAY=:0`, `xclip`), so neovim's
  `"+y` / `"+p` share the Windows clipboard.
- Install a Nerd Font (FiraCode Nerd Font Mono) on the *Windows* side; glyphs
  are rendered by the Windows terminal emulator, not by anything in WSL.
- VM memory/CPU limits live in `%UserProfile%\.wslconfig` on Windows.
