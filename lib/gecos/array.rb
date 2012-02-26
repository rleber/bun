
# TODO Move this to a Gem
class Array
  # Take an array of columns and justify each column so that they're all the same width
  def justify_columns
    widths = self.map do |column|
      column.map{|entry| entry.to_s.size}.max
    end
    justified = []
    self.each_with_index do |column, column_number|
      justified << column.map{|entry| "%-#{widths[column_number]}s" % [entry] }
    end
    justified
  end
  
  # Take an array of rows and justify them so each column is all the same width
  def justify_rows
    self.transpose.justify_columns.transpose
  end
end
