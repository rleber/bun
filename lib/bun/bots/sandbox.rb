class Bun
  class SandboxBot < BotBase
    load_tasks

    desc "foo", "Do other stuff"
    def foo
      puts "In foo"
    end
  end
end
