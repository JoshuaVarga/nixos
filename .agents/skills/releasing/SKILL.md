---
name: releasing
description: Understand and debug this repo's automated versioning, changelog, and GitHub Release pipeline. Use when asked what version the config is on, why a release did or did not fire, how to preview the next version or changelog, or how to undo a bad release. Releases are fully automated by commitizen on every merge to main; nobody cuts one by hand.
---

# Releasing

Versioning is automated. Nobody tags, edits `CHANGELOG.md`, or cuts a release by hand — doing so
by hand will be overwritten or will confuse the next bump.

## The pipeline

```
feature branch (rebased on main) ──PR──> ci: flake check + commit lint
                                              │
                                 human "Rebase and merge"
                                              │
                                              v
                                    .github/workflows/release.yml
        cz bump --files-only ─> cz changelog ─> commit "chore(release): vX.Y.Z" on main
                             ─> tag vX.Y.Z ─> eval host closures ─> gh release create
```

- The version lives in the **git tag**; `.cz.toml` sets `version_provider = "scm"`.
- `VERSION` is a tracked file written by the bump, read by `modules/version.nix` so the version
  reaches the built system. It must stay git-tracked or the flake cannot see it.
- The workflow skips itself when the head commit already starts with `chore(release)`, so it
  cannot loop.
- CI pushing to `main` is the *only* push to `main`; humans merge PRs and never push.

## Preview commands (safe, read-only)

```
cz bump --dry-run --yes     # what version would the next release be
cz changelog --dry-run      # what the changelog would say
git describe --tags         # what version this checkout is at
nixos-version               # what version the running system was built from
```

## Which commits cause a release

Only `feat`, `fix`, `perf`, `refactor` (and any type marked `!`) match `bump_pattern`. A merge
containing nothing but `chore`/`docs`/`style`/`test`/`build`/`ci` produces **no release** — that
is correct behaviour, not a bug. See [`conventional-commits`](../conventional-commits/SKILL.md)
for the full type-to-bump table.

While `major_version_zero = true` in `.cz.toml`, a breaking `!` change bumps MINOR, not MAJOR.
Cutting 1.0 is a deliberate manual act: flip that flag and tag `v1.0.0`.

## Debugging

**No release fired after a merge.**
1. Nothing matched `bump_pattern` — check the merged commits' types. Usually the answer.
2. The head commit started with `chore(release)`, so the guard skipped the run.
3. The push to protected `main` failed — check the workflow log for a 403. `main` requires the
   release workflow's identity to have a bypass on required pull requests, or a PAT secret.

**Release fired but the version is wrong.** `bump_map` in `.cz.toml` is *ordered* and first match
wins, so the `"^.+!:"` MAJOR entry must precede `"^feat"`. If a breaking change only bumped
MINOR, either that ordering broke or `major_version_zero` is still on (expected).

**The changelog is missing entries.** `cz changelog --incremental` only regenerates from the last
tag onward. If earlier sections are wrong, regenerate the whole file with
`cz changelog` (no `--incremental`) and commit the result.

## Undoing a bad release

```
git push --delete origin vX.Y.Z     # remove the tag
gh release delete vX.Y.Z            # remove the GitHub Release
```

Then revert the `chore(release)` commit through a normal PR. Do not force-push `main`. The next
merge that contains a releasable commit will recompute the version from the now-latest tag.

## Where the version shows up

`modules/version.nix` sets, for every host:

- `system.nixos.label` → `<VERSION>.g<shortrev>`, visible in `nixos-version` and the boot menu.
- `system.configurationRevision` → the full git rev the generation was built from.

Note the label is baked from `VERSION` **and** the git rev, so a dirty tree builds a
`...gdirty` label. That is the intended signal that a generation did not come from a release.
