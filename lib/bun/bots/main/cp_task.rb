desc "cp TAPE [DESTINATION]", "Copy a file"
# TODO Refactor :archive as a global option?
option 'archive', :aliases=>'-a', :type=>'string', :desc=>'Archive location'
def cp(tape, dest = nil)
  directory = options[:archive] || Archive.location
  archive = Archive.new(directory)
  unless dest.nil? || dest == '-'
    dest = ::File.join(dest, ::File.basename(tape)) if ::File.directory?(dest)
  end
  archive.open(tape) {|f| Shell.new(:quiet=>true).write dest, f.read }
end
