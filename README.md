# Overview

avsh ("Augmented Vagrant sSH") is a standalone script that emulates `vagrant
ssh`, but is much faster and more convenient when working on synced projects. It
automatically sets up SSH multiplexing the first time it's run, eliminating SSH
connection overhead on subsequent invocations.

```sh
$ /usr/bin/time -f 'WALL TIME=%es CPU=%P' -- vagrant ssh -c 'hostname'
vagrant-ubuntu-trusty-64
Connection to 127.0.0.1 closed.
WALL TIME=2.96s CPU=80%

$ /usr/bin/time -f 'WALL TIME=%es CPU=%P' -- avsh 'hostname'
vagrant-ubuntu-trusty-64
WALL TIME=0.08s CPU=51%
```

Also, it detects when you're working in a synced folder, and automatically
switches to the corresponding directory on the guest before executing commands
or starting a login shell.

```sh
$ echo "host=`hostname`, current directory=$PWD"
host=masons-laptop, current directory=/home/masonm/asci/content

$ avsh 'echo "host=`hostname`, current directory=$PWD"'
host=www.jci.dev, current directory=/var/www/jci/content

$ avsh 'grep synced_folder /vagrant/Vagrantfile'
  config.vm.synced_folder '/home/masonm/asci/', '/var/www/jci'
```

# Caveats

avsh makes a number of assumptions and shortcuts in order to achieve its
performance goals, so it might not work (or be appropriate) for your setup.

* Vagrantfiles are evaluated inside a fake Vagrant environment, which may cause
  issues with complex Vagrantfiles that have conditional logic using Vagrant's
  API. Specifically, the `Vagrant.has_plugin?` method always returns true, and
  other methods on the `Vagrant` module are stubbed out.
* The host must be Linux or OS X 10.7+. It'll probably work on other Unices, but
  hasn't been tested. No limitations on the guest.
* No merging of multiple Vagrantfiles.
* SSH connection details are cached, and must be manually cleared with
  `avsh --reconnect` if the SSH configuration is changed.

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

For multi-machine environments, avsh will infer the machine to connect to by
matching the current directory with the synced folders in your Vagrantfile. If
none are found to match, it will use the primary machine if one exists, else it
uses the first defined machine. You can use the `avsh -m <machine_name>` to
explicitly specify the machine you'd like to connect to.

# Why not make this a Vagrant plugin?

Because I couldn't get this to work as a plugin without sacrificing performance.
The overhead of just getting to the point of executing a command in a plugin is
nearly 1 second on my computer, and I couldn't find a way to decrease that
significantly.
