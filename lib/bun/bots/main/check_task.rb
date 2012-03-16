desc "check FILE", "Test a file for cleanness -- i.e. does it contain non-printable characters?"
def check(file)
  if File.clean?(File.read(file))
    puts "File is clean"
  else
    abort "File is dirty"
  end
end
