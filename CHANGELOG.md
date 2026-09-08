## v0.3.0 (2026-09-08)

### Features

- **desktop**: replace tuigreet with noctalia-greeter
- **dev**: add herdr

### Bug Fixes

- **desktop**: theme the noctalia greeter cursor
- **ai**: survive ollama boot races and truncated gguf downloads
- **ai**: create the ollama directories behind the games mount
- **ai**: fetch qwen38 from a local GGUF instead of the registry
- **ai**: tune qwen3.8 for a 32k gpu-resident context
- **ai**: move the ollama model store off the full root filesystem
- **shell**: update launcher keybind to work with noctalia v5
- **ai**: fit a 128k ollama context in vram with a q8 kv cache

### Refactors

- **ai**: derive the gguf path and host from the ollama config

## v0.2.1 (2026-09-07)

### Bug Fixes

- **ci**: dispatch release explicitly and force-push rebased develop

### Documentation

- explain the release dispatch and develop force-push
- reword branching and release docs for develop branch

### CI

- add weekly develop-to-main release workflow

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
