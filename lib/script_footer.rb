cli = Avsh::CLI.new(AVSH_VAGRANTFILE_DIR, AVSH_VM_NAME)
cli.execute(Dir.pwd, ARGV.join(' '))
