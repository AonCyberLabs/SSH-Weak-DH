FROM alpine:3.18 AS build
WORKDIR /usr/local/src/ssh
COPY resources/openssh.patch .
RUN OPENSSH_VERSION='9.3p1' && \
    ARCHIVE_SHA_256='e9baba7701a76a51f3d85a62c383a3c9dcd97fa900b859bc7db114c1868af8a8' && \
    apk add --virtual .build-deps \
      build-base curl libressl-dev linux-headers zlib-dev && \
    curl -s -O "https://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-${OPENSSH_VERSION}.tar.gz" && \
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

FROM alpine:3.18
ENV PYTHONUNBUFFERED=1
ENV LANG=C.UTF-8
WORKDIR /app
RUN apk add --no-cache bash libressl python3 py3-pip
RUN pip install pipenv
COPY --from=build /usr/local/bin/ssh .
COPY resources/Pipfile .
COPY resources/Pipfile.lock .
COPY resources/ssh-weak-dh-analyze.py .
COPY resources/ssh-weak-dh-test.sh .
COPY resources/configs/ configs/
RUN pipenv install
VOLUME /logs
ENTRYPOINT ["bash", "ssh-weak-dh-test.sh"]
