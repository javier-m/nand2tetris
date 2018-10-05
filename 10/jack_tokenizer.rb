class JackTokenizer
  KEYWORDS = %w(class constructor function method field static var int char boolean void true false null this let do if else while return)
  SYMBOLS = ['{', '}', '(', ')', '[', ']', '.', ',', ';', '+', '-', '*', '/', '&amp;', '|', '&lt;', '&gt;', '=', '~']

  attr_reader :filename, :directory, :content_to_be_tokenized, :current_token, :tokens

  def initialize(input_file)
    @filename = input_file[:filename].match(/(?<filename>\w+)\.jack$/)[:filename]
    @directory = input_file[:directory]
    @content_to_be_tokenized = File.read("#{input_file[:directory]}/#{input_file[:filename]}").strip
    @current_token = nil
    @tokens = []
  end

  def tokenize
    tokenizer_output = File.new("#{@directory}/#{@filename}_ownT.xml", 'w')
    tokenizer_output.puts "<tokens>"
    while has_more_tokens?
      advance
      tokens.push({type: token_type, content: token_content})
      tokenizer_output.puts "<#{token_type}> #{token_content} </#{token_type}>"
    end
    tokenizer_output.puts "</tokens>"
    tokenizer_output.close
  end

  def has_more_tokens?
    @content_to_be_tokenized.length > 0
  end

  def advance
    # advance to next token

    # it there are comments, advance
    first_two_chars = @content_to_be_tokenized[0..1]
    if first_two_chars == '//'
      next_token_position = (@content_to_be_tokenized =~ /$/) + 1
      @content_to_be_tokenized = @content_to_be_tokenized[next_token_position..-1].strip
      advance
      return
    end
    if first_two_chars == '/*'
      next_token_position = (@content_to_be_tokenized =~ /\*\//) + 2
      @content_to_be_tokenized = @content_to_be_tokenized[next_token_position..-1].strip
      advance
      return
    end
    # advance to next non-word character
    # if the token is a string betwen double-quotes, the token includes the double-quotes
    if @content_to_be_tokenized[0] == '"'
      next_token_position = (@content_to_be_tokenized[1..-1] =~ /"/) + 2
      @current_token = @content_to_be_tokenized[0...next_token_position]
      @content_to_be_tokenized = @content_to_be_tokenized[next_token_position..-1].strip
      return
    end

    # if there is only one char left, tokenize it
    if @content_to_be_tokenized.length == 1
      @current_token = @content_to_be_tokenized
      @content_to_be_tokenized = ''
      return
    end

    # if the first char is a non-word char, tokenize it
    if @content_to_be_tokenized[0] =~ /\W/
      case @content_to_be_tokenized[0]
      when '<'
        @current_token = '&lt;'
      when '>'
        @current_token = '&gt;'
      when '&'
        @current_token = '&amp;'
      else
        @current_token = @content_to_be_tokenized[0]
      end
      @content_to_be_tokenized = @content_to_be_tokenized[1..-1].strip
      return
    end

    # otherwise move to next non-word char
    next_token_position = (@content_to_be_tokenized[1..-1] =~ /\W/) + 1
    @current_token = @content_to_be_tokenized[0...next_token_position]
    @content_to_be_tokenized = @content_to_be_tokenized[next_token_position..-1].strip

    return
  end

  def token_type
    if KEYWORDS.include? @current_token
      return 'keyword'
    elsif SYMBOLS.include? @current_token
      return 'symbol'
    elsif is_identifier? @current_token
      return 'identifier'
    elsif is_constant? @current_token
      return 'integerConstant'
    else
      return 'stringConstant'
    end
  end

  def token_content
    if token_type == 'stringConstant'
      @current_token.gsub('"', '')
    else
      @current_token
    end
  end

  # def symbol
  #   @current_token
  # end

  # def identifier
  #   @current_token
  # end

  # def int_val
  #   @current_token.to_i
  # end

  # def string_val
  #   @current_token.gsub('"', '')
  # end

  private

  def is_identifier?(token)
    return !(token =~ /^[a-zA-Z_]\w*$/).nil?
  end

  def is_constant?(token)
    return false unless token =~ /^\d+$/
    return false unless (0..32767).include? token.to_i
    return true
  end
end
