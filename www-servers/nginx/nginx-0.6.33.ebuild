# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/www-servers/nginx/nginx-0.7.16.ebuild,v 1.1 2008/09/08 10:54:08 voxus Exp $

inherit eutils ssl-cert distutils
DESCRIPTION="Robust, small and high performance http and reverse proxy server"

WSGI="mod_wsgi-8994b058d2db"

HOMEPAGE="http://nginx.net/"
SRC_URI="http://sysoev.ru/nginx/${P}.tar.gz
	wsgi? ( http://hg.mperillo.ath.cx/nginx/mod_wsgi/archive/tip.tar.gz )
	"
LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~x86"
IUSE="addition debug fastcgi flv imap pcre perl ssl status sub webdav zlib syslog wsgi"

DEPEND="dev-lang/perl
	pcre? ( >=dev-libs/libpcre-4.2 )
	ssl? ( dev-libs/openssl )
	zlib? ( sys-libs/zlib )
	perl? ( >=dev-lang/perl-5.8 )
	python? ( >=dev-lang/python-2.4 )"

pkg_setup() {
	ebegin "Creating nginx user and group"
	enewgroup nginx
	enewuser nginx -1 -1 /dev/null nginx
	eend ${?}
}

src_unpack() {
        unpack ${A}
        cd "${S}"
	if use syslog; then
        	epatch "${FILESDIR}"/syslog.patch
        fi

	if use wsgi; then
		cd "${WORKDIR}/${WSGI}"
		epatch "${FILESDIR}/mod_wsgi-8994b058d2db.patch"
	fi
	eautoreconf
}

src_compile() {
	local myconf

	# threads support is broken atm.
	#
	# if use threads; then
	# 	einfo
	# 	ewarn "threads support is experimental at the moment"
	# 	ewarn "do not use it on production systems - you've been warned"
	# 	einfo
	# 	myconf="${myconf} --with-threads"
	# fi

	use addition && myconf="${myconf} --with-http_addition_module"
	use fastcgi	|| myconf="${myconf} --without-http_fastcgi_module"
	use fastcgi	&& myconf="${myconf} --with-http_realip_module"
	use flv		&& myconf="${myconf} --with-http_flv_module"
	use zlib	|| myconf="${myconf} --without-http_gzip_module"
	use pcre	|| {
		myconf="${myconf} --without-pcre --without-http_rewrite_module"
	}
	use debug	&& myconf="${myconf} --with-debug"
	use ssl		&& myconf="${myconf} --with-http_ssl_module"
	use imap	&& myconf="${myconf} --with-imap" # pop3/imap4 proxy support
	use perl	&& myconf="${myconf} --with-http_perl_module"
	use status	&& myconf="${myconf} --with-http_stub_status_module"
	use webdav	&& myconf="${myconf} --with-http_dav_module"
	use sub		&& myconf="${myconf} --with-http_sub_module"
	use syslog	&& myconf="${myconf} --with-syslog"
	use wsgi	&& myconf="${myconf} --add-module=../${WSGI}"

	./configure \
		--prefix=/usr \
		--conf-path=/etc/${PN}/${PN}.conf \
		--http-log-path=/var/log/${PN}/access_log \
		--error-log-path=/var/log/${PN}/error_log \
		--pid-path=/var/run/${PN}.pid \
		--http-client-body-temp-path=/var/tmp/${PN}/client \
		--http-proxy-temp-path=/var/tmp/${PN}/proxy \
		--http-fastcgi-temp-path=/var/tmp/${PN}/fastcgi \
		--with-md5-asm --with-md5=/usr/include \
		--with-sha1-asm --with-sha1=/usr/include \
		${myconf} || die "configure failed"

	emake || die "failed to compile"
}

src_install() {
	keepdir /var/log/${PN} /var/tmp/${PN}/{client,proxy,fastcgi}

	dosbin objs/nginx
	cp "${FILESDIR}"/nginx-r1 "${T}"/nginx
	doinitd "${T}"/nginx

	cp "${FILESDIR}"/nginx.conf-r4 conf/nginx.conf

	dodir "${ROOT}"/etc/${PN}
	insinto "${ROOT}"/etc/${PN}
	doins conf/*

	dodoc CHANGES{,.ru} README

	use perl && {
		cd "${S}"/objs/src/http/modules/perl/
		einstall DESTDIR="${D}"|| die "failed to install perl stuff"
	}

	if use wsgi; then
		cd "${WORKDIR}/${WSGI}"
		cp LICENSE  LICENSE.wsgi && dodoc LICENSE.wsgi
		cp README   README.wsgi  && dodoc README.wsgi
		cp NEWS.txt NEWS.wsgi    && dodoc NEWS.wsgi
		cp BUGS     BUGS.wsgi    && dodoc BUGS.wsgi
		cp TODO     TODO.wsgi    && dodoc TODO.wsgi
		insinto /usr/share/doc/${PF}/wsgi_examples
		doins examples/*
		insinto /etc/nginx
		doins conf/wsgi_vars
		dosbin bin/*
	fi
}

pkg_postinst() {
	use ssl && {
		if [ ! -f "${ROOT}"/etc/ssl/${PN}/${PN}.key ]; then
			dodir "${ROOT}"/etc/ssl/${PN}
			insinto "${ROOT}"etc/ssl/${PN}/
			insopts -m0644 -o nginx -g nginx
			install_cert /etc/ssl/nginx/nginx
		fi
	}


	use wsgi && {
		cd "${WORKDIR}/${WSGI}"
		"${python}" setup.py --prefix=/usr/ --sbin-path=/usr/sbin/ --conf-path=/etc/nginx/ || die "wsgi"
	}

}
