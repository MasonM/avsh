# Avsh [![Build Status](https://travis-ci.org/MasonM/avsh.svg?branch=master)](https://travis-ci.org/MasonM/avsh) [![Code Climate](https://codeclimate.com/github/MasonM/avsh/badges/gpa.svg)](https://codeclimate.com/github/MasonM/avsh) [![Coverage](https://codeclimate.com/github/MasonM/avsh/badges/coverage.svg)](https://codeclimate.com/github/MasonM/avsh/coverage)

avsh ("Augmented Vagrant sSH") is a standalone script that can be used in place
of `vagrant ssh`. It provides greatly increased performance and many extra
features.

## Features

* **SSH Multiplexing** avsh automatically establishes an SSH control socket the
  first time it's run, which speeds up all subsequent connections by over an
  order of magnitude.

        ```sh
        $ time vagrant ssh -c 'hostname'
        vagrant-ubuntu-trusty-64
        Connection to 127.0.0.1 closed.

        real    0m2.786s
        user    0m1.670s
        sys     0m0.545s

        $ time avsh hostname
        vagrant-ubuntu-trusty-64
        Shared connection to 127.0.0.1 closed.

        real    0m0.087s
        user    0m0.034s
        sys     0m0.013s
        ```

* **Automatic synced folder switching** avsh detects when you're working in a
  synced folder, and automatically switches to the corresponding directory on
  the guest before executing commands or starting a login shell.

        ```sh
        # in this example, /home/masonm/asci is synced to /var/www/jci on the guest

        $ echo "host=`hostname`, current directory=$PWD"
        host=masons-laptop, current directory=/home/masonm/asci/content

        $ avsh 'echo "host=`hostname`, current directory=$PWD"'
        host=vagrant-ubuntu-trusty-64, current directory=/var/www/jci/content
        ```

* **Run commands on multiple machines** If you have a multi-machine setup, you
  can use `avsh -m` to run a command on multiple machines.

        ```sh
        $ avsh -m 'web,db' df -h
        ```

## Caveats

avsh makes a number of assumptions and shortcuts in order to achieve its
performance goals, so it might not work (or be appropriate) for your setup.

* Vagrantfiles are evaluated inside [a fake Vagrant environment](https://github.com/MasonM/avsh/blob/master/lib/avsh/vagrantfile_environment.rb),
  which may cause issues with complex Vagrantfiles that have conditional logic
  using Vagrant's API. Specifically, the `Vagrant.has_plugin?` method always
  returns true, and other methods on the `Vagrant` module are stubbed out.
* The host must be Linux with OpenSSH 5.6+ or OS X 10.7+. It'll probably work on
  other Unices, but hasn't been tested. No limitations on the guest.
* No merging of multiple Vagrantfiles.

## Installation

Put this script somewhere convenient, and optionally add an alias:
```sh
git clone https://github.com/MasonM/avsh.git

# optional:
echo "alias avsh=\"VAGRANT_CWD='/path/to/vagrant' $(pwd)/avsh/avsh\"" >> ~/.bashrc
```
avsh uses the same `VAGRANT_CWD` environment variable that Vagrant uses to
determine the directory containing the Vagrantfile, defaulting to the current
directory.

## Usage

Run `avsh <command>` to execute a command in the guest machine, or just `avsh`
for a login shell. If you're in a synced folder, it will change to the
corresponding directory on the guest before running the command or starting the
shell.

For multi-machine environments, avsh will infer the machine to connect to using
the synced folders in your Vagrantfile. If none are found to match the current
directory, it will use the primary machine if one exists, else it falls back to
the first defined machine. You can use the `avsh -m <machine_name>` to
explicitly specify the machine you'd like to connect to.

## Why not make this a Vagrant plugin?

Because I couldn't get this to work as a plugin without sacrificing performance.
The overhead of just getting to the point of executing a command in a plugin is
nearly 1 second on my computer, and I couldn't find a way to decrease that
significantly.
