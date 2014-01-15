module Bun

  class File < ::File
    class Deblocked < Bun::File::Unpacked
    end
  end
end
