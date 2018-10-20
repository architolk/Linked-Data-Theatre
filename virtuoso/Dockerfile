#
# NAME     Dockerfile
# VERSION  1.23.0
# DATE     2018-10-20
#
# Copyright 2012-2018
#
# This file is part of the Linked Data Theatre.
#
# The Linked Data Theatre is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# The Linked Data Theatre is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the Linked Data Theatre.  If not, see <http://www.gnu.org/licenses/>.
#

FROM debian:jessie

ENV VIRTUOSO_VERSION 7.2.4.2

RUN set -x \
  && BUILD_DIR="$(mktemp -d)" \
  && BUILD_DEPS="build-essential automake libssl-dev net-tools gawk curl" \
  && apt-get update && apt-get install -y --no-install-recommends $BUILD_DEPS && rm -rf /var/lib/apt/lists/* \
  && curl --insecure -fsSL https://github.com/openlink/virtuoso-opensource/releases/download/v${VIRTUOSO_VERSION}/virtuoso-opensource-${VIRTUOSO_VERSION}.tar.gz | tar xzf - -C "$BUILD_DIR" --strip-components=1 \
  && cd "$BUILD_DIR" \
  && ./configure \
    --prefix=/usr/local \
    --localstatedir=/var \
    --sysconfdir=/etc \
  && make -j$(nproc) \
  && make install \
  && mkdir /etc/virtuoso \
  && mv /var/lib/virtuoso/db/virtuoso.ini /etc/virtuoso \
  && rm -rf "$BUILD_DIR" \
  && apt-get purge -y --auto-remove $BUILD_DEPS \
  && apt-get update && apt-get install -y --no-install-recommends libssl1.0.0 && rm -rf /var/lib/apt/lists/*

ENV VIRTUOSO_DBA_PWD dba

EXPOSE 1111 8890

WORKDIR /var/lib/virtuoso
VOLUME /var/lib/virtuoso

COPY run.sh /run.sh

CMD ["/run.sh"]
