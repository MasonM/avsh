begin
  Avsh::CLI.new(ENV, Dir.pwd).parse_args_and_execute(ARGV)
rescue Avsh::Error => e
  STDERR.puts(e.message)
  exit 1
end
