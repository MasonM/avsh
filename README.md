# avsh

avsh ("Augmented Vagrant sSH") is a standalone script that emulates `vagrant ssh`, but is much faster
and more convienent when working on sync folders. It will automatically set up SSH multiplexing the
first time it's run, which eliminates the overhead of establishing a SSH connection on subsequent
invocations. Additionally, it detects when you're working in a synched folder, and automatically
switches to the corresponding directory on the guest.

# Requirements

* Unix-like OS. Tested on Ubuntu 15.10 and OS X 10.10.
* OpenSSH 5.6+
* Ruby 1.9.3+

# Installation

Put this script somewhere convienent, and optionally add an alias (I use "v"):
```
git clone https://github.com/MasonM/avsh.git
echo "alias v=$(pwd)/avsh/avsh" >> ~/.bashrc # optional
```
avsh has two configuration setings: the name of the VM to connect to (`VM_NAME`) and the directory
containing the Vagrantfile for that VM (`VAGRANTFILE_DIR`). These can be configured by either
directly editing the those constants at the top of the script, adding a `~/.avsh_config` Ruby file
defining those constants, or specify the corresponding environment variables (`AVSH_VM_NAME`
and `AVSH_VAGRANTFILE_DIR`).

# Usage

Run `avsh <command>` to execute a command in the guest VM, or `avsh` for a login shell. If
you're in a synced folder, it will change to the corresponding directory on the guest before running
the command or starting the shell. Otherwise, it changes to `/vagrant`.

# Why not a Vagrant plugin?

Because Vagrant has too much overhead. Just running `vagrant version` takes nearly a second on my
PC, which is enough to be annoying when running tests while developing. avsh has no dependencies, so
its overhead is negligible. 
