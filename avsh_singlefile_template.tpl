#!/bin/sh

# avsh v%{avsh_version} - Augmented Vagrant sSH
# Homepage: https://github.com/MasonM/avsh
# Bugs: https://github.com/MasonM/avsh/issues

set -e -u

# We want to use the Ruby version that Vagrant uses to reduce possible
# compatibility issues when evaluating the Vagrantfile. Thankfully, the Vagrant
# installer uses a bog standard Ruby compiled from source by a Puppet class:
# https://github.com/mitchellh/vagrant-installers/blob/master/substrate/modules/ruby/manifests/source.pp
#
# The location of the embeded Ruby installation is /opt/vagrant/embedded/ for
# Linux and OS X, which is defined at https://github.com/mitchellh/vagrant-installers/tree/master/package/support
# However, old versions of Vagrant for OS X used /Applications/Vagrant/, so we
# ought to check for that too.
for possible_ruby in "/opt/vagrant/embedded/bin/ruby" "/Applications/Vagrant/embedded/bin/ruby" "ruby"; do
  if command -v "$possible_ruby" > /dev/null 2>&1; then
    # The -x flag tells Ruby to ignore everything up to the "#!ruby"
    # The --disable-gems flag is for performance, since we don't need any gems
    exec "$possible_ruby" -x --disable-gems -- "$0" "$@"
  fi
done

echo "avsh was unable to find a suitable Ruby interpreter"
exit 1

#!ruby
%{avsh_libs}

Avsh::CLI.run()
