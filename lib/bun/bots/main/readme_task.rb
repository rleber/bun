desc "readme", "Display helpful information for beginners"
def readme
  STDOUT.write File.read("doc/readme.md")
end
