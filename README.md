# moordrik
Moordrik the lazy Wizard. Helps with installing files, and sometimes spells.

## Overview
Moordrik is a simple shell-based installer that applies package manifests to install scripts, services, files, symbolic links, cleanup entries, and directories.

## Installation
1. Clone or place the repository on the system.
2. From the repo root, install the wizard:
   ```bash
   sudo ./install.sh
   ```
3. Verify the installation:
   ```bash
   moordrik info
   ```

> `install.sh` must be run with `sudo`.

## Usage
The main command is `moordrik` and it accepts a command, a base repository location, and a manifest file location.

```bash
sudo moordrik <command> <base-repo-location> <manifest-file-location>
```

Supported commands:
- `install` — install package files and services
- `uninstall` — remove installed package files and cleanup items
- `validate` — verify the manifest and print planned actions
- `info` — print wizard identity, talent, and release version
- `talent` — print the manifest compatibility version
- `version` — print the wizard release version
- `help` — print usage information

Example:
```bash
sudo moordrik install ~/MyPackage ~/MyPackage/install/MyPackage.manifest
```

## Manifest format
A manifest is a shell script that defines the package and the resources to install.

Common manifest fields:
- `ARCANE_VERSION` — must match the wizard's talent version
- `MANIFEST_VERSION` — manifest schema version
- `MODULE_NAME` — human-readable module name
- `BASE_FILEPATH` — base path inside the package repo for resources
- `EXECUTABLE_SCRIPTS` — array of script names under `${BASE_FILEPATH}/bash`
- `SYSTEMD_SERVICES` — array of service unit filenames under `${BASE_FILEPATH}/services`
- `FILES_TO_MOVE` — associative array of source paths (relative to repo) to full destination paths
- `FILES_TO_LINK` — associative array of absolute source paths to symbolic link destinations
- `FILES_TO_EXECUT` — full system file paths to mark executable
- `FILES_TO_CLEANUP` — full system file paths to remove on uninstall
- `DIRS_TO_CREATE` — full system paths to create before install

The manifest may use `${ORIGINAL_USER_HOME}` to refer to the original sudo user's home directory.

## Notes
- `BASE_REPO_LOCATION` is combined with `BASE_FILEPATH` to form the resource source location.
- `uninstall` may not remove symbolic links in the current version.
- `moordrik` requires `sudo` for install, uninstall, and validate operations.

## Example manifest
See `example/ sample.manifest` for a sample manifest layout and field usage.
 