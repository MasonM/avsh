# Avsh [![Build Status](https://travis-ci.org/MasonM/avsh.svg?branch=master)](https://travis-ci.org/MasonM/avsh) [![Code Climate](https://codeclimate.com/github/MasonM/avsh/badges/gpa.svg)](https://codeclimate.com/github/MasonM/avsh) [![Coverage](https://codeclimate.com/github/MasonM/avsh/badges/coverage.svg)](https://codeclimate.com/github/MasonM/avsh/coverage)

avsh ("Augmented Vagrant sSH") is a standalone script that can be used in place
of `vagrant ssh`. It provides greatly increased performance and several extra
features.

* **SSH multiplexing** avsh automatically establishes an SSH control socket the
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
    # config.vm.synced_folder '/home/masonm/asci/, '/var/www/jci',

    $ pwd
    /home/masonm/asci/content

    $ avsh pwd
    /var/www/jci/content
    ```

* **Run commands on multiple machines** If you have a multi-machine setup, you
  can use `avsh -m` to run a command on multiple machines.

    ```sh
    $ avsh -m 'openbsd,debian' uname
    OpenBSD
    Linux

    $ avsh -m '/(free|open)bsd/' uname
    OpenBSD
    FreeBSD
    ```

## Caveats

avsh makes a number of assumptions and shortcuts in order to achieve its
performance goals, so it might not work (or be appropriate) for your setup.

* Vagrantfiles are evaluated inside [a fake Vagrant environment](https://github.com/MasonM/avsh/blob/master/lib/avsh/vagrantfile_environment.rb),
  which may cause issues with complex Vagrantfiles that use the non-DSL parts of
  Vagrant. Specifically, the `Vagrant.has_plugin?` method always returns true,
  and other methods on the `Vagrant` module are stubbed out.
* The host must be Linux with OpenSSH 5.6+ or OS X 10.7+. It'll probably work on
  other Unices, but hasn't been tested.
* No merging of multiple Vagrantfiles.

## Installation

Download [the latest release](https://github.com/MasonM/avsh/releases/download/0.1/avsh)
and put in your PATH, or run the following:
```sh
curl -sL https://github.com/MasonM/avsh/releases/download/0.1/avsh \
  | sudo tee /usr/local/bin/avsh > /dev/null \
    && sudo chmod ugo+rx /usr/local/bin/avsh

```

avsh uses [the same logic as Vagrant](https://www.vagrantup.com/docs/vagrantfile/#lookup-path)
to find your Vagrantfile.  If you only use a single Vagrantfile, add `export
VAGRANT_CWD="/vagrantfile_dir/"` to your .bashrc or .zshrc to ensure avsh and
Vagrant can always find it.

## Usage

```
Usage: avsh [options] [--] COMMAND    execute given command via SSH
   or: avsh [options]                 start a login shell

Options:
    -m, --machine MACHINE            Target Vagrant machine(s).
                                     Can be specified as a plain string for a single machine, a
                                     comma-separated list for multiple machines, or a regular
                                     expression in the form /search/ for one or more machines.
                                     If not given, will infer from the Vagrantfile.
    -r, --reconnect                  Closes SSH multiplex socket if present and re-initializes it
    -s, --ssh-options OPTS           Additional options to pass to SSH, e.g. "-a -6"
    -d, --debug                      Verbosely print debugging info to STDOUT
    -v, --version                    Display version
    -h, --help                       Display help
    -c, --command COMMAND            Command to execute (only for compatibility with Vagrant SSH)
```

### Multi-Machine Environments

If the `-m` flag is not given for a [multi-machine environment](https://www.vagrantup.com/docs/multi-machine/),
avsh will try to infer the machine to connect to using the synced folders
defined in your Vagrantfile. It does this by matching the current working
directory against each machine in the order they are defined, using the first
machine that has a matching synced folder (taking into account ancestor
directories). If none are found to match, it will use [the primary machine](https://www.vagrantup.com/docs/multi-machine/#specifying-a-primary-machine)
if one exists, else it falls back to the first defined machine.

When executing a command on multiple machines, automatic synced folder switching
is disabled, since that can lead to hard-to-predict behavior. Additionally, a
pseudo-TTY will not be allocated (i.e. SSH will not be passed the '-t' flag).
