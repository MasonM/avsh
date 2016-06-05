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

# Caveats and Requirements

avsh has to make several assumptions in order to achieve its performance goals,
which means it may not be appropriate for your setup. In particular:

* Only Linux and OS X are supported. Probably will work on other Unices, but
  it's only been tested on Ubuntu 15.10 and OS X 10.11.
* Complex Vagrantfiles that have side-effects (e.g. IO operations) may not be
  parsed correctly.
* SSH connection details are cached, and must be manually cleared with
  `avsh --reconnect` if changed.
* If Vagrant is not installed using the [standard installer](https://www.vagrantup.com/downloads.html),
  avsh may not be able to find your Vagrant environment.

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

While it may be possible to do this with a plugin without sacrificing
performance, I wasn't able to get it to work. The overhead of just getting to
the point of executing a command in a plugin is nearly 1 second on my computer.
