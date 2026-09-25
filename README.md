# Testing `dev-util/bats-9999` with Gentoo Docker images

This directory is a small local Gentoo overlay for testing the live
`dev-util/bats-9999` ebuild against the current `bats-core` development branch.

It assumes:

- Docker is installed and working.
- The current working directory is this repository's root.
- No Gentoo Docker containers or local Portage snapshot directory have been created yet.

## First-time setup

Run this from the host:

```bash
docker pull \
  gentoo/portage:latest \
  gentoo/stage3:latest

docker run --rm \
  -v "$PWD/gentoo-portage:/target" \
  gentoo/portage:latest \
  cp -a /var/db/repos/gentoo/. /target/

docker run -it \
  --name gentoo-bats \
  -v "$PWD/gentoo-portage:/var/db/repos/gentoo" \
  -v "$PWD:/var/db/repos/local" \
  gentoo/stage3:latest \
  bash -lc '
    mkdir -p /etc/portage/repos.conf /etc/portage/package.accept_keywords

    cat > /etc/portage/repos.conf/local.conf <<EOF
[local]
location = /var/db/repos/local
masters = gentoo
auto-sync = no
EOF

    echo "=dev-util/bats-9999 **" > /etc/portage/package.accept_keywords/bats

    exec bash
  '

docker image rm \
  gentoo/stage3:latest
```

You are now inside the persistent `gentoo-bats` container.

The local overlay is mounted at:

```text
/var/db/repos/local
```

The ebuild is therefore available as:

```text
/var/db/repos/local/dev-util/bats/bats-9999.ebuild
```

Edits made to the files in this directory on the host are immediately visible
inside the container.

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

## Leave and return later

Leave the container normally:

```bash
exit
```

The container is stopped but not deleted.

Re-enter the same container from the host:

```bash
docker start -ai gentoo-bats
```

The `gentoo-bats` container retains `/etc/portage`, installed packages, Portage
state, and build/test dependencies.

The overlay and Gentoo repository snapshot remain stored below this directory
on the host.

## Re-test after changing the ebuild

Edit the ebuild on the host and then, inside `gentoo-bats`, run:

```bash
FEATURES=test emerge -v =dev-util/bats-9999
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
