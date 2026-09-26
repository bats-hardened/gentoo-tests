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
ebuild /var/db/repos/local/dev-util/bats/bats-9999.ebuild test
```

This runs the phases required by `src_test()` without installing the package.

> To install while running tests use:  
> `FEATURES=test emerge -v =dev-util/bats-9999`

## Re-test after changing the ebuild

Edit the ebuild on the host and then, inside `gentoo-bats`, run:

```bash
ebuild /var/db/repos/local/dev-util/bats/bats-9999.ebuild manifest
```

before running the test again.

## Clean up

Remove the container, Gentoo images, and the portage snapshot with:

```bash
docker rm -f gentoo-bats 2>/dev/null || true
docker image rm gentoo/stage3:latest
sudo rm -rf gentoo-portage
```
