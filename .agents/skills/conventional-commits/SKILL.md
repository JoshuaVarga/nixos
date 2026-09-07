---
name: conventional-commits
description: Write commits that pass this repo's commit-msg hook and land correctly in the changelog. Use before making any commit here, and whenever a commit is rejected by the hook or by the `commits` CI job. This repo enforces Conventional Commits (Angular types) with a fixed scope allowlist, subject line only — no body, no trailers — and rebase-merges every commit onto develop, so each commit ships verbatim.
---

# Conventional commits

Every commit message in this repo is validated by commitizen (`cz check`) — locally through a
`commit-msg` git hook, and again in CI over the whole PR range. The rules are in `.cz.toml`.

## The shape

```
<type>(<scope>)!: <subject>
```

One line. That is the entire message.

```
feat(desktop)!: replace niri with hyprland
fix(host): stop limine getting clobbered on rebuild
build(flake): update noctalia
docs: document the den class mismatch caveat
```

- `type` is required, `scope` is optional, `!` marks a breaking change.
- Subject is lowercase, imperative ("add", not "added"/"adds"), no trailing period, ≤70 chars.
- **No body. No footers. No `Co-Authored-By` or `Claude-Session` trailer.** The validating regex
  is anchored `^...$` over the whole message, so anything after the first line fails.

Rejected, and why:

```
feat(desktop): Replace niri with hyprland     ← capitalised subject
feat(niri): add hyprland                      ← `niri` is not an allowed scope
added hyprland                                ← no type
feat(desktop): replace niri with hyprland     ← body/trailer present; the message
                                                 must be the subject line and nothing else
Co-Authored-By: ...
```

The trailer case matters: several agent harnesses instruct their agents to append attribution
trailers by default. **This repo's rule overrides that instruction.** Do not add them.

## Types

| Type | Use for | Changelog | Bump |
|---|---|---|---|
| `feat` | a new module, host, or capability | Features | MINOR |
| `fix` | a bug fix | Bug Fixes | PATCH |
| `perf` | a performance improvement | Performance | PATCH |
| `refactor` | restructuring with no behaviour change | Refactors | PATCH |
| `docs` | `AGENTS.md`, skills, comments | Documentation | — |
| `build` | flake inputs, `flake.lock`, treefmt | Build | — |
| `ci` | workflows, git hooks | CI | — |
| `test` | checks only | — | — |
| `style` | formatting only | — | — |
| `revert` | reverting a previous commit | — | — |
| `chore` | housekeeping | — | — |

Anything marked `!` is a breaking change. Under the current `major_version_zero = true` policy
that bumps MINOR, not MAJOR — see [`releasing`](../releasing/SKILL.md).

## Scopes

Optional, but must come from this allowlist:

| Scope | Covers |
|---|---|
| `host` | `titan`, `wsl`, hardware, boot/limine, `nvidia`, `memory` |
| `desktop` | `niri`, `noctalia`, cursor theme, greeter |
| `dev` | `dev-tools`, `dev-shell`, git |
| `ai` | `ai.nix` and AI tooling |
| `gaming` | `steam`, `gaming.nix` |
| `shell` | login shell, shell tooling |
| `sec` | `gitleaks`, `vulnix`, hardening |
| `ci` | `.github/workflows` |
| `docs` | `AGENTS.md`, `CLAUDE.md`, skills |
| `flake` | inputs, `flake.lock`, den, treefmt |
| `release` | reserved — only the release workflow uses this |

Omit the scope rather than forcing a bad fit. To add a scope, extend the alternation in
`schema_pattern` **and** the question `choices` in `.cz.toml` — both, or `cz commit` and
`cz check` disagree.

## Procedure

1. **Validate before committing** — cheaper than being rejected by the hook:

   ```
   cz check -m "feat(desktop): add hyprland"
   ```

2. Commit normally. `cz commit` gives an interactive prompt that can only produce a valid
   message, if you prefer it.

3. Before opening a PR, and again whenever `develop` moves, rebase onto `develop`:

   ```
   git fetch origin && git rebase origin/develop
   ```

## Gotchas

- **Every commit ships.** PRs are *rebase*-merged into `develop`, never squashed, so each
  commit lands on `develop` verbatim and gets its own changelog line. There is no squash
  to hide a sloppy intermediate message behind — split work into atomic, individually
  meaningful commits.
- **`develop` moves with every merged PR; `main` only moves weekly.** The weekly merge
  workflow rebases `develop` onto `main` and pushes both, so `main`'s history is a
  subset of `develop`'s (plus the `chore(release)` commits). Always `git fetch` before
  starting new work and rebase against `develop`.
- **`!` is the only breaking-change signal.** There is no `BREAKING CHANGE:` footer here,
  because there are no footers.
- **Never `--no-verify`.** The hook is the only thing standing between a bad message and a
  broken changelog. CI catches it anyway, so bypassing just wastes a round trip.
- **A rejected commit leaves your staged changes intact.** Fix the message and re-run
  `git commit`; nothing is lost.
- **Fixing an already-pushed bad message** is `git rebase -i` plus a force-push of the *feature*
  branch. Never force-push `main`.
