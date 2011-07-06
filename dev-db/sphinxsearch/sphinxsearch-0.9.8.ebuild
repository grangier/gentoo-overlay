# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
 
inherit eutils autotools distutils
 
MY_P="${P/_rc/-rc}"
 
DESCRIPTION="Full-text search engine with support for MySQL and PostgreSQL"
HOMEPAGE="http://www.sphinxsearch.com/"
SRC_URI="http://www.sphinxsearch.com/downloads/sphinx-0.9.8.tar.gz"
 
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86"
IUSE="mysql pgsql debug libstemmer python php"
 
DEPEND="mysql? ( virtual/mysql )
        pgsql? ( dev-db/postgresql )
        python? ( >=dev-lang/python-2.4 )
	php? ( >=dev-lang/php-5.2 )"
 
RDEPEND="${DEPEND}"
CFLAGS="${CFLAGS} -D_FILE_OFFSET_BITS=64"
CXXFLAGS=$CFLAGS
S="${WORKDIR}/sphinx-0.9.8"
 
# is libstemmer used ?
SRC_URI="${SRC_URI} libstemmer? ( http://snowball.tartarus.org/dist/libstemmer_c.tgz )"
 
 
src_unpack() {
        unpack ${A}
        cd "${S}"
        # libstemmer is used
        if use libstemmer; then
                cp -ap ${WORKDIR}/libstemmer_c/* ${S}/libstemmer_c/
        fi
        epatch "${FILESDIR}"/sphinxsearch-0.9.8-fix-sandbox.patch
        eautoreconf
}
 
src_compile() {
 
        econf \
                $(use_with mysql) \
                $(use_with pgsql) \
                $(use_with libstemmer) \
                $(use_with debug) || die "econf failed"
        echo econf
        emake || die "emake failed"
}
 
src_install() {
        cd ${S}
        emake DESTDIR="${D}" install || die "install failed"
	newinitd ${FILESDIR}/sphinx.init sphinx
        dodoc doc/* example.sql
        insinto /etc/sphinxsearch/
        doins sphinx.conf.dist
        doinitd ${FILESDIR}/searchd
 
        # we install python api if python is used
        if use python; then
                distutils_python_version
                site_pkgs="/usr/$(get_libdir)/python${PYVER}/site-packages"
                cd ${S}
                insinto ${site_pkgs}
                doins api/sphinxapi.py
                fperms 777 ${site_pkgs}/sphinxapi.py
        fi

	# we insall php api in /opt/sphinxsearch if used
	if use php; then
		dodir /opt/sphinxsearch
		insinto /opt/sphinxsearch
		doins api/sphinxapi.php
		doins ${FILESDIR}/sphinx.php
	fi
 
        einfo "------------------------------------------------------------------"
        einfo "sphinxsearch has been installed on your system"
        einfo "before starting using sphinxsearch you'll need to"
        einfo
        einfo "cp /etc/sphinxsearch/sphinx.conf.dist /etc/sphinxsearch/sphinx.conf"
        einfo
        einfo "Then to test sphinxsearch you can load sample mysql datas"
        einfo
        einfo "mysql -u test < etc/sphinx/example.sql"
        einfo "indexer --config /etc/sphinx/sphinx.conf --all"
        einfo "search --config /etc/sphinx/sphinx.conf test"
        einfo
        einfo "To start sphinxsearch searchd deamon run"
        einfo
        einfo "/etc/init.d/searchd start"
        einfo
        einfo "To start searchd deamon on boot run"
        einfo
        einfo "rc-update add searchd default"
        einfo
        einfo "Thanks for using sphinxsearch"
        einfo "------------------------------------------------------------------"
}
