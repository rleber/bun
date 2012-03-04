require File.join(File.dirname(__FILE__), '../lib/gecos')
require File.join(File.dirname(__FILE__), '../lib/machine')
require File.join(File.dirname(__FILE__), '../lib/indexable_basic')
require File.join(File.dirname(__FILE__), 'slices.rb')

def capture(*streams)
  streams.map! { |stream| stream.to_s }
  begin
    result = StringIO.new
    streams.each { |stream| eval "$#{stream} = result" }
    yield
  ensure
    streams.each { |stream| eval("$#{stream} = #{stream.upcase}") }
  end
  result.string
end