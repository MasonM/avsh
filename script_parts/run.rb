begin
  Avsh::CLI.new(ENV, Dir.pwd).execute(ARGV)
rescue Avsh::Error => e
  STDERR.puts(e.message)
  exit 1
end
