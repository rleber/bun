#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

no_tasks do
  def compact_groups(archive, &blk)
    shell = Shell.new
    groups = Archive.new(archive).leaves.to_a.group_by {|path| yield(path) }
    # puts groups.inspect
    groups.each do |group, files|
      case files.size
      when 0
        # Shouldn't happen
      when 1
        file = files.first
        unless file == group
          rel_file = file.sub(/^#{archive}\//,'')
          rel_group = group.sub(/^#{archive}\//,'')
          warn "Compact #{rel_file} => #{rel_group}" unless options[:quiet]
          new_file = group
          new_file += File.extname(file) unless File.extname(new_file)==File.extname(file)
          temp_file = group+".tmp"
          shell.mkdir_p(File.dirname(temp_file))
          shell.cp(file, temp_file)
          shell.rm_rf(file)
          shell.rm_rf(group)
          shell.cp(temp_file, new_file)
          shell.rm_rf(temp_file)
        end
      else
        sorted_files = files.map {|file| [file, File.timestamp(file)] }.sort_by {|file, date| date }
        sorted_files.each.with_index do |file_data, index|
          file, date = file_data
          suffix = ".v#{index+1}"
          new_file = group + suffix
          new_file += File.extname(file) unless File.extname(new_file)==File.extname(file)
          shell.mkdir_p(File.dirname(new_file))
          shell.cp(file, new_file)
          shell.rm_rf(file)
          rel_file = file.sub(/^#{archive}\//,'')
          rel_new_file = new_file.sub(/^#{archive}\//,'')
          warn "Move #{rel_file} => #{rel_new_file}" unless options[:quiet]
        end
        shell.rm_rf(group)
      end
    end
  end
end

desc "compress ARCHIVE [TO]", "Compress files in an archive which match on a certain criterion"
option 'dryrun',  :aliases=>'-d', :type=>'boolean', :desc=>"Dryrun; don't actually delete files"
option 'quiet',   :aliases=>'-q', :type=>'boolean', :desc=>"Quiet mode"

long_desc <<-EOT
Compress files in an archive which match on certain criteria.

Analyses are available via the --exam parameter. Available analyses include:\x5

#{String::Examination.exam_definition_table.freeze_for_thor}

The command also allows for evaluating arbitrary Ruby expressions.

TODO Explain expression syntax
TODO Explain how --value works

EOT
def compress(archive, to=nil)
  check_for_unknown_options(archive, to)

  shell = Shell.new
  if to || options[:dryrun]
    shell.rm_rf(to)
    shell.cp_r(archive, to)
    dest = to
  else
    dest = archive
  end

  files = Archive.new(dest).leaves.to_a
  
  # Phase I: Remove duplicates
  dups = Archive.duplicates(files, field: :digest)
  dups.each do |key, files|
    duplicate_files = files[1..-1]
    duplicate_files.each do |file|
      rel_file = file.sub(/^#{dest}\//,'')
      warn "Delete #{rel_file}" unless options[:quiet]
      shell.rm_rf(file) unless options[:dryrun]
    end
  end

  # Phase II: Remove tape files, if there's no difference between them
  compact_groups(dest) {|path| File.dirname(path) }
  
  # Phase III: Compress dated freeze file archives
  compact_groups(dest) {|path| path.sub(/_\d{8}(?:_\d{6})?(?=\/)/,'') }
end
