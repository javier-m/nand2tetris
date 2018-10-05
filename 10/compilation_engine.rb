class CompilationEngine
  # TERMINALS = %w(keyword symbol integerConstant stringConstant identifier)
  # NON_TERMINALS = %w(class classVarDec subroutineDec parameterList subroutineBody)
  # NON_TERMINALS = NON_TERMINALS + %w(statements whileStatement ifStatement returnStatement letStatement doStatement)
  # NON_TERMINALS = NON_TERMINALS + %w(expression term expressionList)

  INDENTATION_SPACES = " " * 2

  OPERATORS = ['+', '-', '*', '/', '&amp;', '|', '&lt;', '&gt;', '=']
  UNARY_OPERATORS = ['-', '~']
  KEYWORD_CONSTANT = %w(true false null this)

  attr_reader :filename, :directory

  def initialize(tokenizer)
    @filename = tokenizer.filename
    @directory = tokenizer.directory
    @tokens = tokenizer.tokens
    @current_token_index = 0
    @current_token = @tokens[@current_token_index]
    @current_indentation = 0
  end

  def compile
    @compiler_output = File.new("#{@directory}/#{@filename}_own.xml", 'w')
    compile_class
    @compiler_output.close
  end

  # --------------------------------------------------
  # Program structure
  # --------------------------------------------------

  def compile_class
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<class>"
    indent
    write_terminal # write <keyword> class </keyword>
    write_terminal # write <identifier> className </identifier>
    write_terminal # write <symbol> { </symbol>

    while @current_token[:content] == 'static' || @current_token[:content] == 'field'
      compile_class_var_dec
    end
    while @current_token[:content] == 'constructor' || @current_token[:content] == 'method' || @current_token[:content] == 'function'
      compile_subroutine_dec
    end

    write_terminal # write <symbol> } </symbol>
    deindent
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</class>"
  end

  def compile_class_var_dec
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<classVarDec>"
    indent
    write_terminal # ('static'|'field')
    write_terminal # type
    write_terminal # varName
    while @current_token[:content] == ','
      write_terminal # ','
      write_terminal # varName
    end
    write_terminal # ';'
    deindent
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</classVarDec>"
  end

  def compile_subroutine_dec
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<subroutineDec>"
    indent
    write_terminal # ('constructor'|'function'|'method')
    write_terminal # ('void'|type)
    write_terminal # subroutineName
    write_terminal # '('
    compile_parameter_list # parameterList
    write_terminal # ')'
    compile_subroutine_body
    deindent
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</subroutineDec>"
  end

  def compile_parameter_list
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<parameterList>"
    indent
    if @current_token[:type] == 'identifier' || @current_token[:content] == 'int' || @current_token[:content] == 'char' || @current_token[:content] == 'boolean'
      write_terminal # type
      write_terminal # varName
    end
    while @current_token[:content] == ','
      write_terminal # ','
      write_terminal # type
      write_terminal # varName
    end
    deindent
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</parameterList>"
  end

  def compile_subroutine_body
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<subroutineBody>"
    indent
    write_terminal # '{'
    while @current_token[:content] == 'var' # varDec
      compile_var_dec
    end
    compile_statements
    write_terminal # '}'
    deindent
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</subroutineBody>"
  end

  def compile_var_dec
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<varDec>"
    indent
    write_terminal # 'var'
    write_terminal # type
    write_terminal # varName

    while @current_token[:content] == ','
      write_terminal # ','
      write_terminal # varName
    end

    write_terminal # ';'
    deindent
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</varDec>"
  end

  # --------------------------------------------------
  # Statements
  # --------------------------------------------------

  def compile_statements
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<statements>"
    indent
    while @current_token[:content] == 'let' || @current_token[:content] == 'if' || @current_token[:content] == 'while' || @current_token[:content] == 'do' || @current_token[:content] == 'return'
      compile_single_statement
    end
    deindent
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</statements>"
  end

  def compile_single_statement
    case @current_token[:content]
    when 'let'
      compile_let_statement
    when 'if'
      compile_if_statement
    when 'while'
      compile_while_statement
    when 'do'
      compile_do_statement
    when 'return'
      compile_return_statement
    end
  end

  def compile_let_statement
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<letStatement>"
    indent
    write_terminal # 'let'
    write_terminal # varName
    if @current_token[:content] == '['
      write_terminal # '['
      compile_expression
      write_terminal # ']'
    end
    write_terminal # '='
    compile_expression
    write_terminal # ';'
    deindent
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</letStatement>"
  end

  def compile_if_statement
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<ifStatement>"
    indent
    write_terminal # 'if'
    write_terminal # '('
    compile_expression
    write_terminal # ')'
    write_terminal # '{'
    compile_statements
    write_terminal # '}'

    if @current_token[:content] == 'else'
      write_terminal # 'else'
      write_terminal # '{'
      compile_statements
      write_terminal # '}'
    end

    deindent
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</ifStatement>"
  end

  def compile_while_statement
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<whileStatement>"
    indent
    write_terminal # 'while'
    write_terminal # '('
    compile_expression
    write_terminal # ')'
    write_terminal # '{'
    compile_statements
    write_terminal # '}'
    deindent
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</whileStatement>"
  end

  def compile_do_statement
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<doStatement>"
    indent
    write_terminal # 'do'
    compile_subroutine_call
    write_terminal # ';'
    deindent
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</doStatement>"
  end

  def compile_return_statement
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<returnStatement>"
    indent
    write_terminal # 'return'
    if @current_token[:content] != ';'
      compile_expression
    end
    write_terminal # ';'
    deindent
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</returnStatement>"
  end

  # --------------------------------------------------
  # Expression
  # --------------------------------------------------

  def compile_expression
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<expression>"
    indent
    compile_term
    if OPERATORS.include? @current_token[:content]
      write_terminal # op
      compile_term
    end
    deindent
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</expression>"
  end

  def compile_term
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<term>"
    indent
    if @current_token[:type] == 'integerConstant'
      write_terminal # integerConstant
    elsif @current_token[:type] == 'stringConstant'
      write_terminal # stringConstant
    elsif KEYWORD_CONSTANT.include? @current_token[:content]
      write_terminal #keywordConstant
    elsif UNARY_OPERATORS.include? @current_token[:content]
      write_terminal # unaryOp
      compile_term
    elsif @current_token[:content] == '('
      write_terminal # '('
      compile_expression
      write_terminal # ')'
    elsif @current_token[:type] == 'identifier'
      if @tokens[@current_token_index + 1][:content] == '(' || @tokens[@current_token_index + 1][:content] == '.'
        compile_subroutine_call
      elsif @tokens[@current_token_index + 1][:content] == '['
        write_terminal # varName
        write_terminal # '['
        compile_expression
        write_terminal # ']'
      else
        write_terminal # varName
      end
    end
    deindent
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</term>"
  end

  def compile_subroutine_call
    case @tokens[@current_token_index + 1][:content]
    when '('
      write_terminal # subroutineName
      write_terminal # '('
      compile_expression_list
      write_terminal # ')'
    when '.'
      write_terminal # className | varName
      write_terminal # '.'
      write_terminal # subroutineName
      write_terminal # '('
      compile_expression_list
      write_terminal # ')'
    end
  end

  def compile_expression_list
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<expressionList>"
    indent
    # expressionLists are called between ()
    # so if the next token is ')', the expressionList is empty
    if @current_token[:content] != ')'
      compile_expression

      # same idea
      while @current_token[:content] != ')'
        write_terminal # ','
        compile_expression
      end
    end

    deindent
    @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</expressionList>"
  end

  private

  def next_token
    @current_token_index += 1
    @current_token = @tokens[@current_token_index]
  end

  def indent
    @current_indentation += 1
  end

  def deindent
    @current_indentation -= 1
  end

  def write_terminal
    @compiler_output.puts INDENTATION_SPACES * @current_indentation + "<#{@current_token[:type]}> #{@current_token[:content]} </#{@current_token[:type]}>"
    next_token
  end

end
