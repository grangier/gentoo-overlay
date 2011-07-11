# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

DESCRIPTION="A collection of command-line tools for processing ODF documents"
HOMEPAGE="http://opendocumentfellowship.com/development/projects/odftools"
SRC_URI="http://opendocumentfellowship.com/~daniel/${P}.tgz"

LICENSE="Apache-2.0 LGPL-2.1"
SLOT="0"
KEYWORDS="~x86"
IUSE=""

DEPEND="
 dev-lang/perl
 dev-libs/libxslt
"
RDEPEND="${DEPEND}"
RESTRICT="primaryuri"

src_install() {
	dobin odfread odf2html
	doman doc/odfread.1 doc/odf2html.1
	insinto "/usr/share/${PN}"
	doins odt2html.xsl odt2html-fast.xsl elinks.conf
}
