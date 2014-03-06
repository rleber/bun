#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "same [OPTIONS] TRAITS... FILES...", "Group files which match on a certain criterion"
option 'asis',    :aliases=>'-a', :type=>'boolean', :desc=>"Do not attempt to decode files"
option 'case',    :aliases=>'-c', :type=>'boolean', :desc=>"Case insensitive"
option 'format',  :aliases=>'-F', :type=>'string',  :desc=>"Use other formats", :default=>'text'
option 'inspect', :aliases=>'-I', :type=>'boolean', :desc=>"Just echo back the value of the traits as received"
option 'justify', :aliases=>'-j', :type=>'boolean', :desc=>"Justify the rows"
option 'min',     :aliases=>'-m', :type=>'numeric', :desc=>"For counting traits: minimum count"
option 'text',    :aliases=>'-x', :type=>'boolean', :desc=>"Based on the text in the file"
option 'usage',   :aliases=>'-u', :type=>'boolean', :desc=>"List usage information"
option 'value',   :aliases=>'-v', :type=>'string',  :desc=>"Set the return code based on whether the" +
                                                           " result matches this value"
long_desc <<-EOT
Group files which match on certain criteria.

Available traits include all file fields, arbitrary Ruby expressions, and the following traits:\x5

#{String::Trait.trait_definition_table.freeze_for_thor}

If you are using more than one trait, separate the traits from the files with the --in parameter.

See the bun help show for more details on traits.
EOT
def same(*args)
  # Check for separator ('--in') between traits and files
  traits, files = split_arguments_at_separator('--in', *args, assumed_before: 1)
  check_for_unknown_options(*traits, *files)

  if options[:usage]
    puts String::Trait.usage
    exit
  end
  
  if options[:inspect]
    puts traits
    exit
  end
  
  case traits.size
  when 0
    stop "!First argument should be an trait expression"
  when 1
    trait = traits.first 
  else
    trait = '[' + traits.join(',') + ']'
  end
  
  stop "!Must provide at least one file " unless files.size > 0


  opts = options.dup # Weird behavior of options here
  asis = opts.delete(:asis)
  options = opts.merge(promote: !asis)

  # TODO DRY this up (same logic in map_task)
  # TODO Allow shard specifiers
  dups = Archive.duplicates(trait, files, options)
  last_key = nil
  dups.keys.sort.each do |key|
    puts "" if last_key
    dups[key].each {|dup| puts ([key] + [dup]).flatten.join('  ')}
    last_key = key
  end
end
