class Bun
  class BotBase < Thor
    def self.command(task_name)
      file_name = ::File.expand_path(::File.join(::File.dirname(__FILE__), 'sandbox', "#{task_name}.rb"))
      code = ::File.read(file_name)
      begin
        eval "class #{self.name}\n#{code}\nend",nil,file_name,0
      rescue => e
        raise "Error defining task #{task_name}: #{e}"
      end
    end
  end

  class SandboxBot < BotBase
    desc "foo", "Do stuff"
    def foo
      puts "In foo"
    end
    command :test
  end
end
