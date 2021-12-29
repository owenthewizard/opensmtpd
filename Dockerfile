FROM alpine:latest AS builder

ENV CC=clang
ENV CFLAGS="-fuse-ld=lld --rtlib=compiler-rt -static-pie -O3 -Wl,-z,now -Wl,-z,relro -Wl,-z,noexecstack -fstack-protector-strong -pipe -fomit-frame-pointer -Wl,--as-needed -Wl,--gc-sections -Wl,--hash-style=gnu -fstack-clash-protection -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fcf-protection -flto -fno-semantic-interposition -fno-common -fno-math-errno -fno-trapping-math -fno-plt"
ENV LD=ld.lld

RUN apk --no-cache add clang lld musl-dev compiler-rt compiler-rt-static binutils fts-dev zlib-dev zlib-static autoconf automake make byacc libevent-dev libevent-static libtool libressl-dev ca-certificates
RUN adduser -D -u 1000 builder

#ADD --chown=builder:builder https://github.com/OpenSMTPD/OpenSMTPD/archive/refs/tags/v6.8.0p2.tar.gz /home/builder/OpenSMTPD-6.8.0p2.tar.gz
COPY --chown=builder:builder OpenSMTPD-6.8.0p2.tar.gz /home/builder/
COPY --chown=builder:builder SHA256SUMS /home/builder/

USER builder:builder
WORKDIR /home/builder

RUN sha256sum -c SHA256SUMS && tar xzf OpenSMTPD-6.8.0p2.tar.gz
WORKDIR /home/builder/OpenSMTPD-6.8.0p2
RUN ./bootstrap && ./configure --with-pic --with-pie --prefix=/usr --sysconfdir=/etc/mail --sbindir=/usr/sbin --with-path-mbox=/var/spool/mail --with-path-empty=/var/empty --with-path-socket=/var/run --libexecdir=/usr/lib/opensmtpd --with-path-CAfile=/etc/ssl/certs/ca-certificates.crt && make && make install-strip DESTDIR=/tmp/opensmtpd
# we don't need docs
RUN rm -rf /tmp/opensmtpd/usr/share
RUN cp etc/aliases usr.sbin/smtpd/smtpd.conf /tmp/opensmtpd/etc/mail/

FROM busybox:musl

COPY --from=builder --chown=0:0 /tmp/opensmtpd/ /
COPY --from=builder --chown=0:0 /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

# some paths smtpd needs
RUN mkdir -p /var/run /var/spool/smtpd /var/empty && chmod 711 /var/spool/smtpd

RUN adduser -h /var/empty -D -H -s /bin/false _smtpd && \
    adduser -h /var/empty -D -H -s /bin/false _smtpq

RUN chgrp _smtpq /usr/sbin/smtpctl && chmod 2555 /usr/sbin/smtpctl

# config
VOLUME /etc/mail
# queue
VOLUME /var/spool/smtpd
# mail - optional with config change
VOLUME /var/spool/mail

EXPOSE 25 465 587

ENTRYPOINT ["/usr/sbin/smtpd", "-d"]
