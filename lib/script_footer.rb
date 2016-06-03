begin
	cli = Avsh::CLI.new(ENV.include?('AVSH_DEBUG'), AVSH_VAGRANTFILE_DIR, AVSH_VM_NAME)
	cli.execute(Dir.pwd, ARGV.join(' '))
rescue Avsh::Error => e
	STDERR.puts(e.message)
	exit 1
end
