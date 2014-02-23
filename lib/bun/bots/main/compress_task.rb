#!/usr/bin/env ruby
# -*- encoding: us-ascii -*-

desc "compress ARCHIVE [TO]", "Compress files in an archive which match on a certain criterion"
option 'dryrun',     :aliases=>'-D', :type=>'boolean', :desc=>"Dryrun; don't actually delete files"
option 'delete',     :aliases=>'-d', :type=>'boolean',  :desc=>"Delete all duplicate files?"
option "force",      :aliases=>'-f', :type=>'boolean', :desc=>"Overwrite existing to directory"
option 'link',       :aliases=>'-l', :type=>'boolean',  :desc=>"Create symlinks for duplicate files?"
option 'quiet',      :aliases=>'-q', :type=>'boolean', :desc=>"Quiet mode"

long_desc <<-EOT
Compress archive.
Removes files in an archive which have identical content, and compresses directories of the form 
path/to/file_<DATETIME>/tape... to path/to/file, provided there's only one tape.

If the compression of tapes described above results in more than one version of the target file,
then they are named path/to/file.V1, path/to/file.V2, etc. (If the file has an extension, this is
appended after the "v1", etc.)

The --delete parameter controls what files are flagged as duplicates, and how they are handled. 
With --delete, ALL files with duplicate content are deleted, except for the oldest one, regardless
of whether all the files have the same target path. Without it, only duplicate versions with exactly
the same target path are deleted.

The --link parameter causes duplicate files (regardless of whether they have the same target path or
not) to be replaced with a symlink to the oldest file with the same content. Note that this only
matters with --no-delete.

As illustration for the above, consider the following example: Three files file1/tape.ar001.0001, 
file1/tape.ar002.0002, and file2/tape.ar003.0003 all have identical content. Assume the files above
are listed in order of creation. Then:

Flag                    Meaning                             Action
--no-delete, --no-link  Delete duplicates with identical    Deletes file1/tape.ar002.0002. Creates
                        target paths. Keep all other        the other two files. No symlinks are
                        duplicates. Do not create symlinks  created.
                        (This is the default.)

--delete,    --no-link  Delete all duplicates, even if      Deletes file1/tape.ar002.0002 and 
                        they have different target paths.   file2/tape.ar003.0003. No symlinks
                        Do not create symlinks.             are created.

--no-delete, --link     Delete duplicates with identical    Deletes file1/tape.ar002.0002
                        target paths. Replace all dup-      Replaces file2/tape.ar003.0003 with a symlink to
                        licate files with symlinks to the   file1/tape.ar001.0001
                        oldest identical file.

--delete,    --link     Delete all duplicates, even if      Deletes file1/tape.ar002.0002 and
                        they have different target paths.   and file2/tape.ar003.0003. No duplicate
                        No links are left to be created.    files are left to be symlinked.
EOT
def compress(archive, to=nil)
  check_for_unknown_options(archive, to)
  Archive.compress(archive, to, options)
end
