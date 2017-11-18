FROM alpine:3.6
COPY . /app/ssh-weak-dh/
WORKDIR /app/ssh-weak-dh/
RUN apk add --no-cache \
      bash libressl python3
ENV OPENSSH_VER 7.3p1
RUN apk add --no-cache --virtual .build-deps \
      build-base curl libressl-dev linux-headers zlib-dev && \
    curl -s -O "https://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-${OPENSSH_VER}.tar.gz" && \
    tar xzf "openssh-${OPENSSH_VER}.tar.gz" && \
    cd openssh-"$OPENSSH_VER" && \
    patch -p1 < ../openssh.patch && \
    patch -p1 < ../bsd-compatible-realpath.patch && \
    ./configure && \
    make ssh && \
    apk del .build-deps
RUN mkdir -p /logs/
ENTRYPOINT ["bash", "ssh-weak-dh-test.sh"]
