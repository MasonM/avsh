# bvsh

bvsh ("Better Vagrant sSH") is a standalone script that emulates `vagrant ssh`, but is much faster
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
git clone https://github.com/MasonM/bvsh.git
echo "alias v=$(pwd)/bvsh/bvsh" >> ~/.bashrc # optional
```

Configuration can be done by directly editing the options at the top of the script, adding a
`~/.bvsh_config` Ruby file defining those options, or specify the corresponding environment
variables.

# Usage

Run `bvsh <command>` to execute a command in the guest VM, or `bvsh` for a login shell. If
you're in a synced folder, it will change to the corresponding directory on the guest before running
the command or starting the shell. Otherwise, it changes to `/vagrant`.

# Why not a Vagrant plugin?

Because Vagrant has too much overhead. Just running `vagrant version` takes nearly a second on my
PC, which is enough to be annoying when running tests while developing. bvsh has no dependencies, so
its overhead is negligible. 
