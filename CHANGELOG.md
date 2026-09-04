## v0.2.0 (2026-09-04)

### Features

- **host**: declare host memory and add a real swapfile

### Bug Fixes

- **host**: stop the nix-daemon memory limits from stalling builds

### Performance

- **ai**: build only ollama with cuda instead of the package set

### Refactors

- **host**: rename oom-hardening to the memory aspect

## v0.1.0 (2026-09-04)

### Features

- **host**: surface release version in the nixos label

### Bug Fixes

- **ci**: capture breaking marker in the bump pattern

### Documentation

- document commit conventions and release flow

### CI

- automate versioning changelog and github releases
- enforce conventional commits with commitizen
