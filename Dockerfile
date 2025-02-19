FROM docker.io/tiredofit/alpine:3.19
LABEL maintainer="Dave Conroy (github.com/tiredofit)"

ENV TINC_VERSION=7eeb29220a73ab9c5367f652873042f8a81c6cef \
    CONTAINER_ENABLE_MESSAGING=FALSE \
    IMAGE_NAME="tiredofit/tinc" \
    IMAGE_REPO_URL="https://github.com/tiredofit/docker-tinc/"

RUN source /assets/functions/00-container && \
    set -x && \
    package update && \
    package upgrade && \
    package add .tinc-build-deps \
				autoconf \
				build-base \
				curl \
				g++ \
				gcc \
				libc-utils \
				libpcap-dev \
				linux-headers \
				lz4-dev \
				lzo-dev \
				make \
				meson \
				ninja \
				ncurses-dev \
				openssl-dev \
				readline-dev \
				tar \
				zlib-dev \
				&& \
	\
    package add .tinc-run-deps \
				ca-certificates \
				git \
				inotify-tools \
				libpcap \
				lz4 \
				lz4-libs \
				lzo \
				openssl \
				ncurses \
				readline \
				zlib && \
	\
    clone_git_repo https://github.com/gsliepen/tinc ${TINC_VERSION} && \
    meson setup builddir -Dprefix=/usr -Dsysconfdir=/etc -Djumbograms=true -Dtunemu=enabled -Dbuildtype=release && \
    meson compile -C builddir && \
    meson install -C builddir && \
    package remove .tinc-build-deps && \
    package cleanup && \
    mkdir -p /var/log/tinc && \
    rm -rf /etc/logrotate.d/* \
    rm -rf /usr/src/*

# squid

RUN apk add --no-cache --purge -uU squid iptables iptables-legacy && \
    rm -rf /var/cache/apk/* /tmp/* && \
    sed -i '1 i\acl all src all' /etc/squid/squid.conf && \
    sed -i '2 i\http_access allow all' /etc/squid/squid.conf && \
    echo 'logfile_rotate 0' >> /etc/squid/squid.conf && \
    echo 'access_log none' >> /etc/squid/squid.conf && \
    echo 'cache_log /dev/null' >> /etc/squid/squid.conf && \
    echo 'cache deny all' >> /etc/squid/squid.conf && \
    echo 'on_unsupported_protocol tunnel all' >> /etc/squid/squid.conf && \
    echo 'via off' >> /etc/squid/squid.conf && \
    echo 'forwarded_for delete' >> /etc/squid/squid.conf && \
    echo 'http_upgrade_request_protocols WebSocket allow all' >> /etc/squid/squid.conf && \
    echo 'http_upgrade_request_protocols OTHER allow all' >> /etc/squid/squid.conf

EXPOSE 655/tcp 655/udp
EXPOSE 3128/tcp

COPY install /