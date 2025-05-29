# About

This tool creates SSH connections to a server and goes through different client
configurations to check if the server permits a Diffie-Hellman (DH) key
exchange using a weak group. We aim for our tool to help assess SSH servers for
weak DH key exchange settings.

Please be aware that this tool tests a limited set of configurations, which
might result in some weak configurations going undetected. Additionally, the
server might block connections before the scan finishes.

For further information about our tool, visit
[https://www.aon.com/cyber-solutions/aon_cyber_labs/ssh-weak-diffie-hellman-group-identification-tool/](https://www.aon.com/cyber-solutions/aon_cyber_labs/ssh-weak-diffie-hellman-group-identification-tool/).

Consult the [Logjam info page](https://weakdh.org/sysadmin.html) for
suggestions on how to configure SSH servers to protect them as well as their
clients from attacks exploiting DH key exchanges using a weak group.

# Installation

1. Install Podman or Docker.
2. Run one of the following commands:
```shell
podman build --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t ssh-weak-dh .
docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t ssh-weak-dh .
```

# Usage

Run one of the following commands:
```shell
podman run --userns=keep-id --rm -v "$(pwd)/logs/":/logs/ ssh-weak-dh host [port]
docker run --rm -v "$(pwd)/logs/":/logs/ ssh-weak-dh host [port]
```
- `host`: Hostname or IP address of the SSH server.
- `port`: Optional SSH server port (default is `22`).

Scan results will be printed to stdout. Detailed results are saved in the
`./logs/` directory under a subfolder named `host-port`.

The scan tool calls the script `ssh-weak-dh-analyze.py` to analyze the scan
results stored in the aforementioned subfolder.

This analysis script is a standalone tool that can be run as follows:
```shell
# Get a container shell:
podman run --userns=keep-id --rm -v "$(pwd)/logs/":/logs/ -it --entrypoint bash ssh-weak-dh
docker run --rm -v "$(pwd)/logs/":/logs/ -it --entrypoint bash ssh-weak-dh

# Run the analysis script on logged scan results:
./ssh-weak-dh-analyze.py /logs/scanme.example.com-22/
```

# Copyright

Fabian Foerg, Gotham Digital Science, 2015-2025

