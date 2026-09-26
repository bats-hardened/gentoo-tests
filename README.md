# Testing bats-core on Gentoo

This directory provides a Docker-based Gentoo environment for testing bats-core
development branches through a live Gentoo ebuild.

It assumes:

- Docker is installed and working.
- The current working directory is this repository's root.
- No Gentoo Docker containers or local Portage snapshot directory have been created yet.

## First-time setup

Run this from the host:

```bash
./setup.sh
```

The persistent `gentoo-bats` container is now configured with the ebuild's
build and test dependencies installed, and stopped.

## Start the test container

Start and attach to the existing container:

```bash
docker start -ai gentoo-bats
```

Leave the container normally with `exit`. The container is stopped but not deleted.

The `gentoo-bats` container retains `/etc/portage`, installed packages, Portage
state, and build/test dependencies.

The overlay and Gentoo repository snapshot remain stored below this directory
on the host.

## Test the ebuild

Inside the container:

```bash
FEATURES=test emerge -v =dev-util/bats-9999
```

This performs a normal Portage build/install and enables the ebuild's
`src_test()` phase.

To inspect the dependency/build plan without merging:

```bash
FEATURES=test emerge -pv =dev-util/bats-9999
```

## Re-test after changing the ebuild

Edit the ebuild on the host and then, inside `gentoo-bats`, run:

```bash
ebuild /var/db/repos/local/dev-util/bats/bats-9999.ebuild manifest
```

Since this is a live `9999` ebuild using `git-r3`, Portage fetches the current
upstream Git state as part of the build.

To force a clean package build first:

```bash
ebuild /var/db/repos/local/dev-util/bats/bats-9999.ebuild clean
FEATURES=test emerge -v =dev-util/bats-9999
```

## Refresh the Gentoo repository snapshot

To recreate the test environment using the current Gentoo images:

```bash
docker rm -f gentoo-bats 2>/dev/null || true
rm -rf gentoo-portage
```

Then repeat the **First-time setup** commands.

Removing the container and `gentoo-portage` directory does not affect the
overlay files themselves.
