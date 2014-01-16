#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

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
  Archive.compress(archive, to, options)
end
