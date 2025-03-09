FROM alpine:3.21 AS build
WORKDIR /usr/local/src/ssh
COPY resources/openssh.patch .
RUN OPENSSH_VERSION='9.9p2' && \
    ARCHIVE_SHA_256='91aadb603e08cc285eddf965e1199d02585fa94d994d6cae5b41e1721e215673' && \
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
WORKDIR /app
COPY resources/.python-version .
COPY resources/uv.lock .
COPY resources/pyproject.toml .
COPY --from=ghcr.io/astral-sh/uv:0.6 /uv /uvx /bin/
RUN apk add --no-cache python3
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --compile-bytecode --no-install-project --no-editable

FROM alpine:3.21
ENV PYTHONUNBUFFERED=1
ENV LANG=C.UTF-8
WORKDIR /app
COPY --from=build /usr/local/bin/ssh .
COPY --from=build /usr/local/src/dh-groups/common.json .
COPY --from=build --chown=app:app /app/.venv .venv
COPY resources/ssh-weak-dh-analyze.py .
COPY resources/ssh-weak-dh-test.sh .
COPY resources/configs/ configs/
RUN apk add --no-cache bash libressl4.0-libcrypto python3
VOLUME /logs
ENTRYPOINT ["bash", "ssh-weak-dh-test.sh"]
