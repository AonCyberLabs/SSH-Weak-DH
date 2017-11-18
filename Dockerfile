FROM alpine:3.6
WORKDIR /app/
COPY configs/ ./configs/
COPY bsd-compatible-realpath.patch openssh.patch \
  ssh-weak-dh-analyze.py ssh-weak-dh-test.sh ./
RUN apk add --no-cache \
      bash libressl python3
ENV OPENSSH_VERSION 7.3p1
RUN apk add --no-cache --virtual .build-deps \
      build-base curl libressl-dev linux-headers zlib-dev && \
    curl -s -O "https://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-${OPENSSH_VERSION}.tar.gz" && \
    tar xzf "openssh-${OPENSSH_VERSION}.tar.gz" && \
    rm -f "openssh-${OPENSSH_VERSION}.tar.gz" && \
    cd "openssh-${OPENSSH_VERSION}" && \
    patch -p1 < ../openssh.patch && \
    patch -p1 < ../bsd-compatible-realpath.patch && \
    ./configure && \
    make ssh && \
    cp ssh .. && \
    cd .. && \
    rm -rf "openssh-${OPENSSH_VERSION}/" *.patch && \
    apk del .build-deps
RUN mkdir /logs/
ENTRYPOINT ["bash", "ssh-weak-dh-test.sh"]
