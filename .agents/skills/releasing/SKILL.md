---
name: releasing
description: Understand and debug this repo's automated versioning, changelog, and GitHub Release pipeline. Use when asked what version the config is on, why a release did or did not fire, how to preview the next version or changelog, or how to undo a bad release. Releases are fully automated on a weekly develop→main cycle; nobody cuts one by hand.
---

# Releasing

Versioning is automated. Nobody tags, edits `CHANGELOG.md`, or cuts a release by hand — doing so
by hand will be overwritten or will confuse the next bump.

## The pipeline

```
feature branch (rebased on develop) ──PR──> ci: flake check + commit lint
                                              │
                                 human "Rebase and merge" into develop
                                              │
                                              v
                          .github/workflows/weekly-release.yml
     weekly (Mon 04:00 UTC, or dispatch): rebase develop onto main, push both,
                          then `gh workflow run release.yml --ref main`
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
- Humans never push to `main` or `develop` directly. The weekly merge workflow pushes both
  (skipping entirely when `develop` has no commits ahead of `main`), and `release.yml`
  pushes `main` again with the `chore(release)` commit.
- The weekly workflow *dispatches* `release.yml` rather than relying on its `push` trigger:
  a push authenticated with the default `GITHUB_TOKEN` never raises workflow events, so the
  `on: push` path alone would silently never fire.
- The push to `develop` is `--force-with-lease`. The rebase rewrites every `develop`-only
  commit, so a plain push would be rejected as non-fast-forward once `main` carries a
  `chore(release)` commit that `develop` lacks.

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
1. `develop` had no commits ahead of `main` that week — the weekly merge workflow skipped,
   so `release.yml` never fired. Check `git rev-list --count origin/main..develop`; a
   no-diff week means no tag.
2. Nothing matched `bump_pattern` — check the merged commits' types. Usually the answer.
3. The push to protected `main` failed — check the workflow log for a 403. `main` requires the
   release workflow's identity to have a bypass on required pull requests, or a PAT secret.

**Release fired but the version is wrong.** Two traps in `.cz.toml`, both silent:

1. `bump_map` keys are matched against **group(1) of `bump_pattern`**, not the whole commit
   message. `bump_pattern` therefore wraps the type, scope and `!` in one outer group. Rewrite it
   without that group and every breaking change quietly degrades to a MINOR bump.
2. `bump_map` is *ordered* and first match wins, so the `"^.+!:"` MAJOR entry must precede
   `"^feat"`.

If a breaking change only bumped MINOR and both of those are intact, it's `major_version_zero`
doing its job — expected until 1.0.

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
