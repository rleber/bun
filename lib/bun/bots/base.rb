class Bun
  class BotBase < Thor
    def self.calling_file
      call_stack = caller.map{|c| [c[/^(.*):\d+/,1],c[/in\s+`(.*)'/,1]]}
      called_from = call_stack.find{|c| c[0] != call_stack[0][0]}
      called_from && called_from[0]
    end
    
    def self.task_directory
      called_from = calling_file
      ::File.expand_path(::File.join(::File.dirname(called_from), ::File.basename(called_from,'.*')))
    end
    
    def self.task_names
      Dir.glob(::File.join(task_directory,'*.rb')).map{|t| ::File.basename(t, '.*')}
    end
    
    def self.load_tasks
      puts "in #{self}.load_tasks: task_names = #{task_names.inspect}"
      task_names.each {|task| load_task task}
    end
    
    def self.load_task(task_name, file_name=nil)
      file_name ||= ::File.join(task_directory, "#{task_name}.rb")
      code = ::File.read(file_name)
      begin
        eval "class #{self.name}\n#{code}\nend",nil,file_name,0
      rescue => e
        raise "Error defining task #{task_name}: #{e}"
      end
    end
  end
end
