FROM alpine:3.19 AS build
WORKDIR /usr/local/src/ssh
COPY resources/openssh.patch .
RUN OPENSSH_VERSION='9.8p1' && \
    ARCHIVE_SHA_256='dd8bd002a379b5d499dfb050dd1fa9af8029e80461f4bb6c523c49973f5a39f3' && \
    apk add --virtual .build-deps \
      build-base curl libressl-dev linux-headers zlib-dev && \
    curl -s -S -L -O "https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-${OPENSSH_VERSION}.tar.gz" && \
    CHECKSUM=$(sha256sum "openssh-${OPENSSH_VERSION}.tar.gz" | awk '{print $1;}') && \
    echo "Checksum is $CHECKSUM" && \
    [ "$CHECKSUM" = "$ARCHIVE_SHA_256" ] && \
    echo "Checksum is valid" && \
    tar xzf "openssh-${OPENSSH_VERSION}.tar.gz" && \
    cd "openssh-${OPENSSH_VERSION}" && \
    patch -p1 < ../openssh.patch && \
    ./configure && \
    make ssh && \
    mv ssh /usr/local/bin/
WORKDIR /usr/local/src/dh-groups
RUN curl -s -S -L -O 'https://raw.githubusercontent.com/cryptosense/diffie-hellman-groups/04610a10e13db3a69c740bebac9cb26d53c520d3/gen/common.json'

FROM alpine:3.19
ENV PYTHONUNBUFFERED=1
ENV LANG=C.UTF-8
WORKDIR /app
COPY --from=build /usr/local/bin/ssh .
COPY resources/ssh-weak-dh-analyze.py .
COPY resources/ssh-weak-dh-test.sh .
COPY resources/configs/ configs/
COPY resources/Pipfile .
COPY resources/Pipfile.lock .
COPY --from=build /usr/local/src/dh-groups/common.json .
RUN apk add --no-cache bash libressl3.8-libcrypto python3 py3-pip && \
  rm /usr/lib/python3.*/EXTERNALLY-MANAGED && \
  pip install --no-cache-dir pipenv && \
  pipenv install --system --deploy --clear && \
  pip uninstall pipenv -y && \
  apk del py3-pip
VOLUME /logs
ENTRYPOINT ["bash", "ssh-weak-dh-test.sh"]
