# Testing `dev-util/bats-9999` with Gentoo Docker images

This directory is a small local Gentoo overlay for testing the live
`dev-util/bats-9999` ebuild against the current `bats-core` development branch.

It assumes:

- Docker is installed and working.
- No Gentoo Docker containers or volumes have been created yet.

The setup follows Gentoo's documented use of `gentoo/portage` as a
`/var/db/repos/gentoo` data volume together with `gentoo/stage3`.

## First-time setup

Run this from the host:

```bash
docker pull \
  gentoo/portage:latest \
  gentoo/stage3:latest

docker create \
  -v /var/db/repos/gentoo \
  --name gentoo-portage \
  gentoo/portage:latest \
  /bin/true

docker run -it \
  --name gentoo-bats \
  --volumes-from gentoo-portage \
  -v "$PWD/bats-core/gentoo-overlay:/var/db/repos/local" \
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
```

You are now inside the persistent `gentoo-bats` container. The local overlay is
mounted at:

```text
/var/db/repos/local
```

The ebuild is therefore available as:

```text
/var/db/repos/local/dev-util/bats/bats-9999.ebuild
```

The overlay itself remains on the host, so edits made to
`gentoo-overlay/dev-util/bats/bats-9999.ebuild` are immediately visible inside
the container.

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

Do **not** use `docker run --rm ...` for subsequent sessions. That would create
a fresh disposable container and lose `/etc/portage`, installed packages, and
other container state.

The `gentoo-bats` container retains:

- `/etc/portage` configuration
- installed packages
- Portage state
- build/test dependencies

The overlay itself remains persistently stored on the host.

## Re-test after changing the ebuild

Edit the ebuild on the host and then, inside `gentoo-bats`, run:

```bash
FEATURES=test emerge -v =dev-util/bats-9999
```

Since this is a live `9999` ebuild using `git-r3`, Portage fetches the current
upstream Git state as part of the build.

If you want to force a completely clean package build first:

```bash
ebuild /var/db/repos/local/dev-util/bats/bats-9999.ebuild clean
FEATURES=test emerge -v =dev-util/bats-9999
```

## Refresh the Gentoo repository snapshot

The `gentoo-portage` container holds the repository snapshot from the
`gentoo/portage:latest` image that existed when it was created.

To replace the whole test environment with current images, remove both
containers and recreate them using the first-time setup above:

```bash
docker rm -f gentoo-bats gentoo-portage
docker pull gentoo/portage:latest gentoo/stage3:latest
```

Then run the **First-time setup** commands again.

Removing these containers does not affect the local overlay.
