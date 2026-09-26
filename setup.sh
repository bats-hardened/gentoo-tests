#!/usr/bin/env bash

set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

docker run --rm \
  -v "$script_dir/gentoo-portage:/target" \
  gentoo/portage:latest \
  cp -a /var/db/repos/gentoo/. /target/

docker image rm \
  gentoo/portage:latest

docker container create -it \
  --name gentoo-bats \
  -v "$script_dir/etc-portage/repos.conf/local.conf:/etc/portage/repos.conf/local.conf" \
  -v "$script_dir/etc-portage/package.accept_keywords/bats:/etc/portage/package.accept_keywords/bats" \
  -v "$script_dir/gentoo-portage:/var/db/repos/gentoo" \
  -v "$script_dir/local_overlay:/var/db/repos/local" \
  gentoo/stage3:latest

docker start gentoo-bats
docker exec gentoo-bats emerge --getbinpkg --onlydeps -v =dev-util/bats-9999
docker stop gentoo-bats
