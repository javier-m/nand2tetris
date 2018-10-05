require_relative 'vm_writer'

class CompilationEngine
  # TERMINALS = %w(keyword symbol integerConstant stringConstant identifier)
  # NON_TERMINALS = %w(class classVarDec subroutineDec parameterList subroutineBody)
  # NON_TERMINALS = NON_TERMINALS + %w(statements whileStatement ifStatement returnStatement letStatement doStatement)
  # NON_TERMINALS = NON_TERMINALS + %w(expression term expressionList)

  # INDENTATION_SPACES = " " * 2

  OPERATORS = ['+', '-', '*', '/', '&amp;', '|', '&lt;', '&gt;', '=']
  UNARY_OPERATORS = ['-', '~']
  KEYWORD_CONSTANT = %w(true false null this)

  attr_reader :filename, :directory

  # def initialize(compiler_output, tokenizer)
  #   @compiler_output = compiler_output

  #   @filename = tokenizer.filename
  #   @directory = tokenizer.directory
  #   @tokens = tokenizer.tokens
  #   @current_token_index = 0
  #   @current_token = @tokens[@current_token_index]
  #   @previous_token = nil
  #   @current_indentation = 0

  #   @symbol_table = SymbolTable.new
  #   @last_kind_seen = ''
  #   @last_type_seen = ''

  #   @vm_writer = VMWriter.new(compiler_output)
  # end

  def initialize(compiler_output, tokenizer)
    @compiler_output = compiler_output

    @filename = tokenizer.filename
    @directory = tokenizer.directory
    @tokens = tokenizer.tokens
    @current_token_index = 0
    @current_token = @tokens[@current_token_index]
    @previous_token = nil
    # @current_indentation = 0

    @symbol_table = SymbolTable.new
    @class_name = ''
    @nb_if = 0
    @nb_while = 0

    @vm_writer = VMWriter.new(compiler_output)
  end

  def compile
    compile_class
  end

  # --------------------------------------------------
  # Program structure
  # --------------------------------------------------

  # def compile_class
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<class>"
  #   indent
  #   write_terminal # write <keyword> class </keyword>
  #   @last_kind_seen = @previous_token[:content] # 'class'
  #   write_new_terminal_symbol # write <identifier> className </identifier>
  #   write_terminal # write <symbol> { </symbol>

  #   while @current_token[:content] == 'static' || @current_token[:content] == 'field'
  #     compile_class_var_dec
  #   end
  #   while @current_token[:content] == 'constructor' || @current_token[:content] == 'method' || @current_token[:content] == 'function'
  #     compile_subroutine_dec
  #   end

  #   write_terminal # write <symbol> } </symbol>
  #   deindent
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</class>"
  # end

  def compile_class
    next_token # 'class' ->
    last_kind_seen = @previous_token[:content] # 'class'
    @class_name = @current_token[:content]
    next_token # className ->
    next_token # '{' ->

    while @current_token[:content] == 'static' || @current_token[:content] == 'field'
      compile_class_var_dec
    end
    while @current_token[:content] == 'constructor' || @current_token[:content] == 'method' || @current_token[:content] == 'function'
      compile_subroutine
    end

    next_token # '}' ->
  end

  # def compile_class_var_dec
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<classVarDec>"
  #   indent
  #   write_terminal # ('static'|'field')
  #   @last_kind_seen = @previous_token[:content] # ('static'|'field')
  #   write_terminal # type
  #   @last_type_seen = @previous_token[:content] # type
  #   write_new_terminal_symbol # varName
  #   while @current_token[:content] == ','
  #     write_terminal # ','
  #     write_new_terminal_symbol # varName
  #   end
  #   write_terminal # ';'
  #   deindent
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</classVarDec>"
  # end

  def compile_class_var_dec
    next_token # ('static'|'field') ->
    @last_kind_seen = @previous_token[:content] # ('static'|'field')
    next_token # type ->
    @last_type_seen = @previous_token[:content] # type
    update_symbol_table
    next_token # varName ->
    while @current_token[:content] == ','
      next_token # ',' ->
      update_symbol_table
      next_token # varName ->
    end
    next_token # ';' ->
  end

  # def compile_subroutine_dec
  #   @symbol_table.start_subroutine

  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<subroutineDec>"
  #   indent
  #   write_terminal # ('constructor'|'function'|'method')
  #   @last_kind_seen = 'subroutine'
  #   write_terminal # ('void'|type)
  #   @last_type_seen = @previous_token[:content] # ('void'|type)
  #   write_new_terminal_symbol # subroutineName
  #   write_terminal # '('
  #   compile_parameter_list # parameterList
  #   write_terminal # ')'
  #   compile_subroutine_body
  #   deindent
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</subroutineDec>"
  # end

  def compile_subroutine
    @symbol_table.start_subroutine

    # subroutine declaration
    subroutine_kind = @current_token[:content] # ('constructor'|'function'|'method')
    next_token # ('constructor'|'function'|'method') ->
    next_token # ('void'|type) ->
    subroutine_name = @current_token[:content] #subroutineName
    next_token # subroutineName ->
    full_subroutine_name = "#{@class_name}.#{subroutine_name}"
    @current_label_namespace = full_subroutine_name
    @nb_if = 0
    @nb_while = 0
    next_token # '(' ->
    compile_parameter_list # parameterList
    next_token # ')' ->

    # subroutine body
    next_token # '{' ->
    # count nb of locals
    n_locals = 0
    while @current_token[:content] == 'var' # varDec
      n_locals += compile_var_dec
    end

    # write subroutine declaration
    @vm_writer.write_function(full_subroutine_name, n_locals)

    # if the subroutine is a method set this base to arg 0
    if subroutine_kind == 'method'
      @vm_writer.write_push('argument', '0') # reference to object base
      @vm_writer.write_pop('pointer', '0') # this
      # arg 0 is this
      @symbol_table.shift_arg_index # arg 0 -> arg 1, arg n -> arg n+1
    # if the subroutine is a constructor allocate memory
    elsif subroutine_kind == 'constructor'
      nb_fields= @symbol_table.var_count 'field'
      @vm_writer.write_push('constant', "#{nb_fields}")
      @vm_writer.write_call('Memory.alloc', '1') # allocate memory for object create and return base address
      @vm_writer.write_pop('pointer', '0') # set base address of this to the newly allocated memory base
    end

    # compile subroutine body (var declaration excepted)
    compile_statements
    next_token # '}' ->
  end

  # def compile_parameter_list
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<parameterList>"
  #   indent
  #   @last_kind_seen = 'arg'
  #   if @current_token[:type] == 'identifier' || @current_token[:content] == 'int' || @current_token[:content] == 'char' || @current_token[:content] == 'boolean'
  #     write_terminal # type
  #     @last_type_seen = @previous_token[:content] # type
  #     write_new_terminal_symbol # varName
  #   end
  #   while @current_token[:content] == ','
  #     write_terminal # ','
  #     write_terminal # type
  #     @last_type_seen = @previous_token[:content] # type
  #     write_new_terminal_symbol # varName
  #   end
  #   deindent
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</parameterList>"
  # end

  def compile_parameter_list
    @last_kind_seen = 'arg'
    if @current_token[:type] == 'identifier' || @current_token[:content] == 'int' || @current_token[:content] == 'char' || @current_token[:content] == 'boolean'
      next_token # type ->
      @last_type_seen = @previous_token[:content] # type
      update_symbol_table
      next_token # varName ->
    end
    while @current_token[:content] == ','
      next_token # ',' ->
      next_token # type ->
      @last_type_seen = @previous_token[:content] # type
      update_symbol_table
      next_token # varName ->
    end
  end

  # def compile_subroutine_body
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<subroutineBody>"
  #   indent
  #   write_terminal # '{'
  #   while @current_token[:content] == 'var' # varDec
  #     compile_var_dec
  #   end
  #   compile_statements
  #   write_terminal # '}'
  #   deindent
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</subroutineBody>"
  # end

  # def compile_var_dec
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<varDec>"
  #   indent
  #   write_terminal # 'var'
  #   @last_kind_seen = @previous_token[:content] # 'var'
  #   write_terminal # type
  #   @last_type_seen = @previous_token[:content] # type
  #   write_new_terminal_symbol  # varName

  #   while @current_token[:content] == ','
  #     write_terminal # ','
  #     write_new_terminal_symbol  # varName
  #   end

  #   write_terminal # ';'
  #   deindent
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</varDec>"
  # end

  def compile_var_dec
    n_var = 0
    next_token # 'var' ->
    @last_kind_seen = @previous_token[:content] # 'var'
    next_token # type ->
    @last_type_seen = @previous_token[:content] # type
    update_symbol_table
    n_var += 1
    next_token  # varName ->

    while @current_token[:content] == ','
      next_token # ',' ->
      update_symbol_table
      n_var += 1
      next_token  # varName ->
    end

    next_token # ';' ->

    return n_var
  end

  # # --------------------------------------------------
  # # Statements
  # # --------------------------------------------------

  # def compile_statements
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<statements>"
  #   indent
  #   while @current_token[:content] == 'let' || @current_token[:content] == 'if' || @current_token[:content] == 'while' || @current_token[:content] == 'do' || @current_token[:content] == 'return'
  #     compile_single_statement
  #   end
  #   deindent
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</statements>"
  # end

  def compile_statements
    while @current_token[:content] == 'let' || @current_token[:content] == 'if' || @current_token[:content] == 'while' || @current_token[:content] == 'do' || @current_token[:content] == 'return'
      compile_single_statement
    end
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

  # def compile_let_statement
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<letStatement>"
  #   indent
  #   write_terminal # 'let'
  #   write_terminal_symbol # varName
  #   if @current_token[:content] == '['
  #     write_terminal # '['
  #     compile_expression
  #     write_terminal # ']'
  #   end
  #   write_terminal # '='
  #   compile_expression
  #   write_terminal # ';'
  #   deindent
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</letStatement>"
  # end

  def compile_let_statement
    next_token # 'let' ->
    var_name = @current_token[:content]
    segment = @symbol_table.kind_of var_name
    index = @symbol_table.index_of var_name
    next_token # varName ->
    if @current_token[:content] == '['
      # bar[k]
      @vm_writer.write_push(segment, index) # push bar
      next_token # '[' ->
      compile_expression # push k
      next_token # ']' ->
      @vm_writer.write_arithmetics('+') # bar + k

      next_token # '=' ->
      compile_expression
      next_token # ';' ->
      @vm_writer.write_pop('temp', '0') # temporary storage of the expression result

      @vm_writer.write_pop('pointer', '1') # pop *(bar + k) => that 0
      @vm_writer.write_push('temp', '0')
      @vm_writer.write_pop('that', '0')
    else
      next_token # '=' ->
      compile_expression
      next_token # ';' ->
      @vm_writer.write_pop(segment, index)
    end
  end

  # def compile_if_statement
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<ifStatement>"
  #   indent
  #   write_terminal # 'if'
  #   write_terminal # '('
  #   compile_expression
  #   write_terminal # ')'
  #   write_terminal # '{'
  #   compile_statements
  #   write_terminal # '}'

  #   if @current_token[:content] == 'else'
  #     write_terminal # 'else'
  #     write_terminal # '{'
  #     compile_statements
  #     write_terminal # '}'
  #   end

  #   deindent
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</ifStatement>"
  # end

  def compile_if_statement
    increment_nb_loops('if')
    label_1 = define_label('if', 'L1')
    unnest_label_namespace
    label_2 = define_label('if', 'L2')

    next_token # 'if' ->
    next_token # '(' ->
    compile_expression # push expression
    @vm_writer.write_arithmetics_unop('~') # 'not'
    next_token # ')' ->

    @vm_writer.write_if label_1
    next_token # '{' ->
    compile_statements

    @vm_writer.write_goto label_2
    next_token # '}' ->
    @vm_writer.write_label label_1

    if @current_token[:content] == 'else'
      next_token # 'else' ->
      next_token # '{' ->
      compile_statements
      next_token # '}' ->
    end
    @vm_writer.write_label label_2

    unnest_label_namespace
  end

  # def compile_while_statement
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<whileStatement>"
  #   indent
  #   write_terminal # 'while'
  #   write_terminal # '('
  #   compile_expression
  #   write_terminal # ')'
  #   write_terminal # '{'
  #   compile_statements
  #   write_terminal # '}'
  #   deindent
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</whileStatement>"
  # end

  def compile_while_statement
    increment_nb_loops('while')
    label_1 = define_label('while', 'L1')
    unnest_label_namespace
    label_2 = define_label('while', 'L2')

    next_token # 'while' ->
    @vm_writer.write_label label_1
    next_token # '(' ->
    compile_expression # push expression
    @vm_writer.write_arithmetics_unop('~') # 'not'
    next_token # ')' ->
    @vm_writer.write_if label_2
    next_token # '{' ->
    compile_statements
    @vm_writer.write_goto label_1
    next_token # '}' ->
    @vm_writer.write_label label_2

    unnest_label_namespace
  end

  # def compile_do_statement
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<doStatement>"
  #   indent
  #   write_terminal # 'do'
  #   compile_subroutine_call
  #   write_terminal # ';'
  #   deindent
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</doStatement>"
  # end

  def compile_do_statement
    next_token # 'do' ->
    compile_subroutine_call
    @vm_writer.write_pop('temp', '0') # for void method/function pop the arbitrary return 0
    next_token # ';' ->
  end

  # def compile_return_statement
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<returnStatement>"
  #   indent
  #   write_terminal # 'return'
  #   if @current_token[:content] != ';'
  #     compile_expression
  #   end
  #   write_terminal # ';'
  #   deindent
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</returnStatement>"
  # end

  def compile_return_statement
    next_token # 'return' ->
    if @current_token[:content] != ';'
      compile_expression
    else
      @vm_writer.write_push('constant', '0') # for void method/function arbitrarily return 0
    end
    @vm_writer.write_return
    next_token # ';' ->
  end

  # # --------------------------------------------------
  # # Expression
  # # --------------------------------------------------

  # def compile_expression
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<expression>"
  #   indent
  #   compile_term
  #   if OPERATORS.include? @current_token[:content]
  #     write_terminal # op
  #     compile_term
  #   end
  #   deindent
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</expression>"
  # end

  def compile_expression
    compile_term
    while OPERATORS.include? @current_token[:content]
      operator = @current_token[:content]
      next_token # op ->
      compile_term
      @vm_writer.write_arithmetics(operator)
    end
  end

  # def compile_term
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<term>"
  #   indent
  #   if @current_token[:type] == 'integerConstant'
  #     write_terminal # integerConstant
  #   elsif @current_token[:type] == 'stringConstant'
  #     write_terminal # stringConstant
  #   elsif KEYWORD_CONSTANT.include? @current_token[:content]
  #     write_terminal #keywordConstant
  #   elsif UNARY_OPERATORS.include? @current_token[:content]
  #     write_terminal # unaryOp
  #     compile_term
  #   elsif @current_token[:content] == '('
  #     write_terminal # '('
  #     compile_expression
  #     write_terminal # ')'
  #   elsif @current_token[:type] == 'identifier'
  #     if @tokens[@current_token_index + 1][:content] == '(' || @tokens[@current_token_index + 1][:content] == '.'
  #       compile_subroutine_call
  #     elsif @tokens[@current_token_index + 1][:content] == '['
  #       write_terminal_symbol # varName
  #       write_terminal # '['
  #       compile_expression
  #       write_terminal # ']'
  #     else
  #       write_terminal_symbol # varName
  #     end
  #   end
  #   deindent
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</term>"
  # end

  def compile_term
    if @current_token[:type] == 'integerConstant'
      @vm_writer.write_push('constant', @current_token[:content])
      next_token # integerConstant ->
    elsif @current_token[:type] == 'stringConstant'
      # save current pointer
      @vm_writer.write_push('pointer', '0')
      @vm_writer.write_pop('temp', '0')
      # create String object
      string = @current_token[:content]
      @vm_writer.write_push('constant', "#{string.length}")
      @vm_writer.write_call('String.new', '1')
      @vm_writer.write_pop('pointer', '0')

      # push String object pointer on the stack
      @vm_writer.write_push('pointer', '0')

      # populate String object
      string.each_codepoint do |c|
        @vm_writer.write_push('constant', "#{c}")
        @vm_writer.write_call('String.appendChar', '2') # return string base address
      end

      # retrieve original pointer
      @vm_writer.write_push('temp', '0')
      @vm_writer.write_pop('pointer', '0')

      next_token # stringConstant ->
    elsif KEYWORD_CONSTANT.include? @current_token[:content]
      case @current_token[:content]
      when 'true'
        @vm_writer.write_push('constant', 1)
        @vm_writer.write_arithmetics_unop('-') # neg 1 => -1 = true
      when 'false'
        @vm_writer.write_push('constant', 0)
      when 'null'
        @vm_writer.write_push('constant', 0)
      when 'this'
        @vm_writer.write_push('pointer', 0)
      end
      next_token # keywordConstant ->
    elsif UNARY_OPERATORS.include? @current_token[:content]
      unitary_operator = @current_token[:content]
      next_token # unaryOp ->
      compile_term
      @vm_writer.write_arithmetics_unop(unitary_operator)
    elsif @current_token[:content] == '('
      next_token # '(' ->
      compile_expression
      next_token # ')' ->
    elsif @current_token[:type] == 'identifier'
      if @tokens[@current_token_index + 1][:content] == '(' || @tokens[@current_token_index + 1][:content] == '.'
        compile_subroutine_call
      elsif @tokens[@current_token_index + 1][:content] == '['
        # bar[k]
        var_name = @current_token[:content]
        segment = @symbol_table.kind_of var_name
        index = @symbol_table.index_of var_name
        @vm_writer.write_push(segment, index) # push bar
        next_token # varName ->
        next_token # '[' ->
        compile_expression # push k
        next_token # ']' ->
        @vm_writer.write_arithmetics('+') # bar + k
        @vm_writer.write_pop('pointer', '1') # pop *(bar+k) => that 0
        @vm_writer.write_push('that', '0') # push that 0 = bar[k]
      else
        var_name = @current_token[:content]
        segment = @symbol_table.kind_of var_name
        index = @symbol_table.index_of var_name
        @vm_writer.write_push(segment, index)
        next_token # varName ->
      end
    end
  end

  # def compile_subroutine_call
  #   case @tokens[@current_token_index + 1][:content]
  #   when '('
  #     write_terminal_symbol('subroutine') # subroutineName - can be defined later in the code
  #     write_terminal # '('
  #     compile_expression_list
  #     write_terminal # ')'
  #   when '.'
  #     write_terminal_symbol('class') # className | varName
  #     write_terminal # '.'
  #     write_terminal_symbol('subroutine') # subroutineName
  #     write_terminal # '('
  #     compile_expression_list
  #     write_terminal # ')'
  #   end
  # end

  def compile_subroutine_call

    case @tokens[@current_token_index + 1][:content]
    when '('
      # method call
      n_args = 1
      class_name = @class_name
      subroutine_name = @current_token[:content]
      @vm_writer.write_push('pointer', '0')
      next_token # subroutineName ->
      next_token # '(' ->
      n_args += compile_expression_list
      next_token # ')' ->
    when '.'
      identifier_name = @current_token[:content] # varName or className
      segment = @symbol_table.kind_of identifier_name
      if segment == 'none' # the identifier is a className
        n_args = 0
        class_name = identifier_name
      else # the identifier is an object
        n_args = 1
        class_name = @symbol_table.type_of identifier_name
        segment = @symbol_table.kind_of identifier_name
        index = @symbol_table.index_of identifier_name
        @vm_writer.write_push(segment, index)
      end
      next_token # (className | varName) ->
      next_token # '.' ->
      subroutine_name = @current_token[:content]
      next_token # subroutineName ->
      next_token # '(' ->
      n_args += compile_expression_list
      next_token # ')' ->
    end

    full_subroutine_name = "#{class_name}.#{subroutine_name}"
    @vm_writer.write_call(full_subroutine_name, n_args)
  end

  # def compile_expression_list
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "<expressionList>"
  #   indent
  #   # expressionLists are called between ()
  #   # so if the next token is ')', the expressionList is empty
  #   if @current_token[:content] != ')'
  #     compile_expression

  #     # same idea
  #     while @current_token[:content] != ')'
  #       write_terminal # ','
  #       compile_expression
  #     end
  #   end
  #   deindent
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation +  "</expressionList>"
  # end

  def compile_expression_list
    # expressionLists are called between ()
    n_args = 0
    # so if the next token is ')', the expressionList is empty
    if @current_token[:content] != ')'
      compile_expression
      n_args += 1

      # same idea
      while @current_token[:content] != ')'
        next_token # ',' ->
        compile_expression
        n_args += 1
      end
    end
    return n_args
  end

  private

  def next_token
    @previous_token = @current_token
    @current_token_index += 1
    @current_token = @tokens[@current_token_index]
  end

  def increment_nb_loops(loop_type)
    nb_loops = instance_variable_get("@nb_#{loop_type}").to_i
    instance_variable_set("@nb_#{loop_type}", nb_loops + 1)
  end

  def define_label(loop_type, label)
    nb_loops = instance_variable_get("@nb_#{loop_type}").to_i
    instance_variable_set("@nb_#{loop_type}", 0)
    @current_label_namespace = "#{@current_label_namespace}.#{loop_type}_#{nb_loops}"
    return "#{@current_label_namespace}.#{label}"
  end

  def unnest_label_namespace
    nested_namespace_pattern = /(?<label_namespace>.+)\.(?<loop_type>\w+)_(?<nb_loops>\d+)$/
    @current_label_namespace =~ nested_namespace_pattern
    unnested_label_data = @current_label_namespace.match(nested_namespace_pattern)
    @current_label_namespace = unnested_label_data[:label_namespace]
    loop_type = unnested_label_data[:loop_type]
    nb_loops = unnested_label_data[:nb_loops].to_i
    instance_variable_set("@nb_#{loop_type}", nb_loops)
  end

  def update_symbol_table
      # add symbol to the symbol table
      identifier_name = @current_token[:content]
      @symbol_table.define_identifier({ name: identifier_name, type: @last_type_seen, kind: @last_kind_seen })
  end

  # def indent
  #   @current_indentation += 1
  # end

  # def deindent
  #   @current_indentation -= 1
  # end

  # def write_terminal
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation + "<#{@current_token[:type]}> #{@current_token[:content]} </#{@current_token[:type]}>"
  #   next_token
  # end

  # def write_new_terminal_symbol
  #   # add symbol to the symbol table
  #   identifier_name = @current_token[:content]
  #   @symbol_table.define_identifier({ name: identifier_name, type: @last_type_seen, kind: @last_kind_seen })
  #   status = "status='defined'"
  #   type = @last_type_seen.empty? ? '' : "type='#{@last_type_seen}'"
  #   kind = @last_kind_seen.empty? ? '' : "kind='#{@last_kind_seen}'"
  #   identifier_index = @symbol_table.kind_of(identifier_name) == 'none' ? '' : "index='#{@symbol_table.index_of(identifier_name)}'"
  #   attributes = "#{status} #{type} #{kind} #{identifier_index}".squeeze(' ')
  #   # write <identifier kind='xxx' type='yyy' index='zzz'> SymbolName </identifier>
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation + "<identifier #{attributes}> #{identifier_name} </identifier>"
  #   next_token
  # end

  # def write_terminal_symbol(input_kind = nil)
  #   identifier_name = @current_token[:content]
  #   status = "status='used'"
  #   if input_kind.nil? # the symbol is already in the table
  #     kind = "kind='#{@symbol_table.kind_of identifier_name}'"
  #     type = "type='#{@symbol_table.type_of identifier_name}'"
  #     identifier_index = "index='#{@symbol_table.index_of identifier_name}'"
  #   else
  #     # the symbol is not in the table because there is a method call from an external class
  #     # or a function call where the function is defined later in the code
  #     kind = "kind='#{input_kind}'"
  #     type = ''
  #     identifier_index = ''
  #   end
  #   attributes = "#{status} #{type} #{kind} #{identifier_index}".squeeze(' ')
  #   # write <identifier kind='xxx' type='yyy' index='zzz'> SymbolName </identifier>
  #   @compiler_output.puts INDENTATION_SPACES * @current_indentation + "<identifier #{attributes}> #{identifier_name} </identifier>"
  #   next_token
  # end
end
