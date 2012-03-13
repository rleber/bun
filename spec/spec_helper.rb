require File.join(File.dirname(__FILE__), '../lib/gecos')
require File.join(File.dirname(__FILE__), '../lib/slicr')
require File.join(File.dirname(__FILE__), '../lib/indexable_basic')
require File.join(File.dirname(__FILE__), '../lib/gecos')
require File.join(File.dirname(__FILE__), 'slices.rb')

# Usage capture :stdout, :stderr { foo } => <contents of all streams>
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