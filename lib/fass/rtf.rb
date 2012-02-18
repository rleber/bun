module RTF
  class Parser
    attr_accessor :rtf
    def initialize(rtf)
      @rtf = rtf
    end
    
    def tokens
      rtf.gsub(/[\n\r]/,'').scan(/(?:\\[a-zA-Z]+(?:-?[0-9]+)?)|\{|\}|(?:\\'\d+)|\\[^a-zA-Z]|[^\\{}]+/)
    end
    
    TRANSLATIONS = {
      "\\tab" => "\t",
      "\\emspace" => " ",
      "\\enspace" => " ",
      "\\qmspace" => " ",
      "\\~" => ' ',          # Non-breaking space
      "\\bullet" => "*",
      "\\emdash" => '--',
      "\\endash" => '-',
      "\\_" => '-',         # Non-breaking hyphen
      "\\lquote" => "'",
      "\\rquote" => "'",
      "\\ldblquote" => '"',
      "\\rdblquote" => '"',
      "\\par" => "\n",
      "\\sect" => "\n",
      "\\page" => "\n",
      "\\line" => "\n",
      "\\lbr0" => "\n",
      "\\lbr1" => "\n",
      "\\lbr2" => "\n",
      "\\lbr3" => "\n",
    }
    
    def translate(token)
      TRANSLATIONS[token] || token
    end
  
    def translated_tokens
      tokens.map{|t| translate(t) }
    end
    
    def text
      blocks = parse do |block|
        block.each_index do |i|
          if block[i].is_a?(String)
            block[i] = translate(block[i])
          end
        end
        if block.size > 0
          # unless block[0..1] == ["\\*", "\\panose"]
          #   p block 
          #   exit unless get_logical("Okay? ")
          # end
          case block.first
          when "\\fonttbl", "\\sp", "\\info", "\\stylesheet"
            block.clear
          when "\\*"
            block.clear unless block[1] == "\\shpinst"
          end
        end
        block
      end
      blocks.flatten.reject {|t| t =~ /^[\\{}]/ }.join
    end
    
    def token_set
      toks = tokens
      tokset = Hash.new(0)
      toks.each do |t|
        if t=~ /^\\([a-zA-Z]+)/
          tokset[$1] += 1
        end
      end
      tokset
    end
    
    def parse(&blk)
      t = tokens
      blocks = []
      pos = _parse(t, 0, blocks, &blk)
      raise "Unbalanced braces" unless pos >= t.size
      blocks
    end
    
    def _parse(toks, pos, blocks, &blk)
      while pos < toks.size
        if toks[pos] == '{'
          subblocks = []
          pos = _parse(toks, pos+1, subblocks, &blk)
          blocks << subblocks unless subblocks.nil?
        elsif toks[pos] == '}'
          pos += 1
          break
        else
          blocks << toks[pos]
          pos += 1
        end
      end
      if block_given?
        blocks = yield(blocks)
      end
      return pos
    end
  end
  private :_parse
  
  def print(&blk)
    _print_code(parse(&blk))
  end
  
  def _print_code(chunks, level=0)
    return if level > 1
    chunks.each do |chunk|
      if chunk.is_a?(Array)
        print_chunks(chunk, level+1)
      else
        i = chunk.inspect
        prefix = '  '*level
        if i.size>100
          puts "#{prefix}#{i[0...50]}..#{i[-50..-1]}"
        else 
          puts "#{prefix}#{i}"
        end
      end
    end
  end
  private :_print_chunks
end
