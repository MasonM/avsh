begin
  Avsh::CLI.new(ENV).parse_args_and_execute(Dir.pwd, ARGV)
rescue Avsh::Error => e
  STDERR.puts(e.message)
  exit 1
end
