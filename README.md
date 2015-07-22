# About

This tool establishes SSH connections to a server, thereby enumerating through various client configurations, in order to determine whether the server allows a Diffie-Hellman (DH) key exchange based on a weak group.
We hope that our tool will be useful to check SSH servers for weak DH key exchange configurations.

For further information about our tool, visit [http://blog.gdssecurity.com/](http://blog.gdssecurity.com/).

# Installation

## Requirements

This tool was tested under Ubuntu 14.04.
Although we have not tested our tool with other Linux distributions, its dependencies do not restrict its use to Ubuntu.

The setup script downloads, patches, and compiles a portable OpenSSH variant for Linux.
For this process to succeed, you need to have the dependencies for compiling OpenSSH installed.

Other requirements include the bash shell and Python 2.7 or later.

## Command

On a Linux machine change to this directory and run:

~~~
chmod +x *.sh *.py
./setup.sh
~~~

# Usage

Run `./logjam-test.sh hostname [port]`. The results are printed on stdout.
More detailed results can be found in the `logjam` directory under the subfolder
whose name has the form `hostname-port` where `hostname` and `port` are the
corresponding command line parameters.

The `logjam-test.sh` script calls the analysis script `logjam-analyze.py` to analyze the results stored in the aforementioned subfolder.
Our analysis script is a standalone script and can be run on a results folder as follows:

~~~
./logjam-analyze.py logjam/localhost-22
~~~

The example above analyzes the results of the scan for the SSH server running on port 22 on localhost.

