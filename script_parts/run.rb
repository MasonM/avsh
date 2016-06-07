begin
  # May exit at this point if "--help" or "--version" supplied
  options, command = Avsh::ArgumentParser.parse(ARGV)

  Avsh::CLI.new(ENV).execute(Dir.pwd, options, command)
rescue Avsh::Error => e
  STDERR.puts(e.message)
  if options[:debug]
    STDERR.puts(e.backtrace.join("\n"))
  end
  exit 1
end
