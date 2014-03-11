module Bun

  class File < ::File
    class Deblocked < Bun::File::Unpacked
      # TODO: Is this class actually used anywhere?
    end
  end
end
