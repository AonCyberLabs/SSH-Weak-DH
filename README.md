# About

This tool establishes SSH connections to a server, thereby enumerating through various client configurations, in order to determine whether the server allows a Diffie-Hellman (DH) key exchange based on a weak group.
We hope that our tool will be useful to check SSH servers for weak DH key exchange configurations.

For further information about our tool, visit [http://blog.gdssecurity.com/labs/2015/8/3/ssh-weak-diffie-hellman-group-identification-tool.html](http://blog.gdssecurity.com/labs/2015/8/3/ssh-weak-diffie-hellman-group-identification-tool.html).

# Installation

## Requirements

This tool was tested under Ubuntu 14.04 and Mac OS X Yosemite.
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

Run `./ssh-weak-dh-test.sh hostname [port]`. The results are printed on stdout.
More detailed results can be found in the `ssh-weak-dh` directory under the subfolder
whose name has the form `hostname-port` where `hostname` and `port` are the
corresponding command line parameters.

The `ssh-weak-dh-test.sh` script calls the analysis script `ssh-weak-dh-analyze.py` to analyze the results stored in the aforementioned subfolder.
Our analysis script is a standalone script and can be run on a results folder as follows:

~~~
./ssh-weak-dh-analyze.py ssh-weak-dh/localhost-22
~~~

The example above analyzes the results of the scan for the SSH server running on port 22 on localhost.

