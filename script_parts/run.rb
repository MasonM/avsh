begin
	logger = Avsh::Logger.new(ENV.include?('AVSH_DEBUG'))
	cli = Avsh::CLI.new(logger, AVSH_VAGRANTFILE_DIR, AVSH_VM_NAME)
	cli.execute(Dir.pwd, ARGV.join(' '))
rescue Avsh::Error => e
	STDERR.puts(e.message)
	exit 1
end
