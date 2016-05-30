# avsh

avsh ("Augmented Vagrant sSH") is a standalone script that emulates `vagrant ssh`, but is much
faster and more convenient when working on synced projects. It automatically sets up SSH
multiplexing the first time it's run, eliminating SSH connection overhead on subsequent invocations.
Also, it detects when you're working in a synced folder, and automatically switches to the
corresponding directory on the guest before executing commands or starting a login shell.

# Requirements

* POSIX-compliant OS. Tested on Ubuntu 15.10 and OS X 10.10.
* OpenSSH 5.6+
* Ruby 1.9.3+
* Vagrant 1.0+

# Installation

Put this script somewhere convenient, and optionally add an alias (I use "v"):
```
curl -o avsh https://raw.githubusercontent.com/MasonM/avsh/master/avsh
chmod +x avsh

# optional:
echo "alias v=$(pwd)/avsh" >> ~/.bashrc
```
avsh has two configuration setings: the name of the VM to connect to (`AVSH_VM_NAME`) and the
directory containing the Vagrantfile for that VM (`AVSH_VAGRANTFILE_DIR`). These can be configured
by either editing the script to change those constants, adding a `~/.avsh_config` file defining them
(see `avsh_config_example.rb` for an example), or specify the corresponding environment variables
(`AVSH_VM_NAME` and `AVSH_VAGRANTFILE_DIR`).

# Usage

Run `avsh <command>` to execute a command in the guest VM, or just `avsh` for a login shell. If
you're in a synced folder, it will change to the corresponding directory on the guest before running
the command or starting the shell. Otherwise, it changes to `/vagrant`.

# Why not make this a Vagrant plugin?

Because Vagrant has too much overhead. Just running `vagrant version` takes nearly a second on my
PC, which is enough to be annoying when running tests while developing. avsh has no dependencies, so
its overhead is negligible. 
