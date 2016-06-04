# Overview

avsh ("Augmented Vagrant sSH") is a standalone script that emulates `vagrant
ssh`, but is much faster and more convenient when working on synced projects. It
automatically sets up SSH multiplexing the first time it's run, eliminating SSH
connection overhead on subsequent invocations.

```sh
$ time vagrant ssh -c 'hostname'
www.jci.dev
Connection to 127.0.0.1 closed.
1.11s user 0.16s system 77% cpu 1.652 total

$ time avsh 'hostname'
www.jci.dev
0.03s user 0.00s system 32% cpu 0.086 total
```

Also, it detects when you're working in a synced folder, and automatically
switches to the corresponding directory on the guest before executing commands
or starting a login shell.

```sh
$ echo "host=`hostname`	current directory=$PWD"
host=masons-laptop      current directory=/home/masonm/asci/content

$ avsh 'echo "host=`hostname`	current directory=$PWD"'
host=www.jci.dev        current directory=/var/www/jci/content

$ avsh 'grep synced_folder /vagrant/Vagrantfile'
  config.vm.synced_folder '/home/masonm/asci/', '/var/www/jci'
```

# Requirements

* Linux or OS X. Probably will work on other Unices, but it's only been tested
  on Ubuntu 15.10 and OS X 10.11.
* OpenSSH 5.6+
* Vagrant 1.0+

# Installation

Put this script somewhere convenient, and optionally add an alias:
```sh
git clone https://github.com/MasonM/avsh.git

# optional:
echo "alias avsh=\"VAGRANT_CWD='/path/to/vagrant' $(pwd)/avsh/avsh\"" >> ~/.bashrc
```
avsh uses the same `VAGRANT_CWD` environment variable that Vagrant uses to
determine the directory containing the Vagrantfile, defaulting to the current
directory.

# Usage

Run `avsh <command>` to execute a command in the guest machine, or just `avsh`
for a login shell. If you're in a synced folder, it will change to the
corresponding directory on the guest before running the command or starting the
shell. Otherwise, it changes to `/vagrant`.

For multi-machine environments, avsh will infer the machine using synced folders,
using the first defined machine that maps the folder you're in. If none are
found, it will use the primary machine if one exists, else it uses the first
defined machine.

# Why not make this a Vagrant plugin?

Because Vagrant has too much overhead. Just running `vagrant version` takes
nearly a second on my PC, which is enough to be annoying when running tests
while developing. avsh has no Ruby dependencies, so its overhead is negligible.
