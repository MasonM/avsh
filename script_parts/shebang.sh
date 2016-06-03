#!/bin/sh

# avsh v0.1 - Augmented Vagrant sSH
# Homepage: https://github.com/MasonM/avsh
# Bugs: https://github.com/MasonM/avsh/issues
# Enable debug output by prepending AVSH_DEBUG=1 (e.g. 'AVSH_DEBUG=1 avsh ls')

# https://github.com/mitchellh/vagrant-installers/tree/master/package/support
for ruby_path in "/opt/vagrant/embedded/bin/ruby" "/Applications/Vagrant/embedded/bin/ruby"; do
	if [ -x "$ruby_path" ]; then
		exec "$ruby_path" -x -- $0 "$@"
	fi
done

if command -v given-command > /dev/null 2>&1; then
	# Fall back to system ruby
	exec "$ruby_path" -x -- $0 "$@"
else
	echo "Unable to find Ruby environment"
	exit 1
fi

#!ruby
