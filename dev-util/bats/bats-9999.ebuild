# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=9

inherit git-r3 multiprocessing optfeature

MY_PN="bats-core"
DESCRIPTION="Bats-core: Bash Automated Testing System"
HOMEPAGE="https://github.com/bats-core/bats-core/"
EGIT_REPO_URI="https://github.com/bats-core/bats-core.git"
EGIT_BRANCH="master"

LICENSE="MIT"
SLOT="0"

DEPEND="app-shells/bash:*"
RDEPEND="${DEPEND}"

src_test() {
	local my_jobs=$(get_nproc)
	if ! command -v parallel >/dev/null; then
		my_jobs=1
	fi
	# see https://github.com/bats-core/bats-core/issues/1225
	# BATS_NUMBER_OF_PARALLEL_JOBS should be the same as "--jobs" as we had before
	# but turns out they are not so testing like upstream does
	BATS_NUMBER_OF_PARALLEL_JOBS="${my_jobs}" bin/bats --tap test || die "Tests failed"
}

src_install() {
	exeinto /usr/libexec/${MY_PN}
	doexe libexec/${MY_PN}/*
	exeinto /usr/lib/${MY_PN}
	doexe lib/${MY_PN}/*
	dobin bin/${PN}

	dodoc README.md
	doman man/${PN}.1 man/${PN}.7
}

pkg_postinst() {
	optfeature "Parallel Execution" sys-process/parallel
}

