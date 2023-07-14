# About

This tool establishes SSH connections to a server, thereby enumerating through
various client configurations, in order to determine whether the server allows
a Diffie-Hellman (DH) key exchange based on a weak group.  We hope that our
tool will be useful to check SSH servers for weak DH key exchange
configurations.

Note that this tool tests a limited number of configurations and therefore
potentially fails to detect some weak configurations. Moreover, the server
possibly blocks connections before the scan completes.

For further information about our tool, visit
[https://www.aon.com/cyber-solutions/aon_cyber_labs/ssh-weak-diffie-hellman-group-identification-tool/](https://www.aon.com/cyber-solutions/aon_cyber_labs/ssh-weak-diffie-hellman-group-identification-tool/).

Consult the [Logjam info page](https://weakdh.org/sysadmin.html) for
suggestions on how to configure SSH servers to protect them as well as their
clients from attacks exploiting DH key exchanges using a weak group.

# Installation

Install docker and execute the following command:
```bash
docker build -t ssh-weak-dh .
```

# Usage

Run the following commands:
```bash
docker run --rm -v "$(pwd)/logs/":/logs/ ssh-weak-dh hostname [port]
```
where `hostname` is the host name or IP address of the SSH server to scan. The
optional argument `port` allows you to specify the port on which the SSH server
listens. If the argument is not specified, it will default to `22`.

The scan results are printed on stdout.

More detailed results can be found in the `./logs/` directory under the
subfolder whose name has the form `hostname-port` where `hostname` and `port`
are the corresponding command line parameters.

The scan tool calls the script `ssh-weak-dh-analyze.py` to analyze the scan
results stored in the aforementioned subfolder.  This analysis script is a
standalone tool.

For example, run the following command to analyze the results of a scan of the
SSH server running on port 22 on scanme.example.com:
```bash
docker run --rm -v "$(pwd)/logs/":/logs/ -it --entrypoint python3 ssh-weak-dh -u ssh-weak-dh-analyze.py /logs/scanme.example.com-22/
```

It is also possible to run the scan script inside the container shell as
follows:
```bash
./ssh-weak-dh-test.sh hostname [port]
```
where `hostname` and `port` are the scanner arguments as explained before.

# Copyright

Fabian Foerg, Gotham Digital Science, 2015-2023

