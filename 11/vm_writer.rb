class VMWriter
  def initialize(compiler_output)
    @compiler_output = compiler_output
  end

  def write_push(segment, index)
    @compiler_output.puts "push #{print_segment(segment)} #{index}"
  end

  def write_pop(segment, index)
    @compiler_output.puts "pop #{print_segment(segment)} #{index}"
  end

  def write_arithmetics(operator)
    printed_operator = case operator
    when '+'
      'add'
    when '-'
      'sub'
    when '*'
      'call Math.multiply 2'
    when '/'
      'call Math.divide 2'
    when '&amp;'
      'and'
    when '|'
      'or'
    when '&lt;'
      'lt'
    when '&gt;'
      'gt'
    when '='
      'eq'
    end
    @compiler_output.puts printed_operator
  end

  def write_arithmetics_unop(unitary_operator)
    printed_operator = case unitary_operator
    when '-'
      'neg'
    when '~'
      'not'
    end
    @compiler_output.puts printed_operator
  end

  def write_label(label)
    @compiler_output.puts "label #{label}"
  end

  def write_goto(label)
    @compiler_output.puts "goto #{label}"
  end

  def write_if(label)
    @compiler_output.puts "if-goto #{label}"
  end

  def write_call(full_subroutine_name, n_args)
    @compiler_output.puts "call #{full_subroutine_name} #{n_args}"
  end

  def write_function(name, n_locals)
    @compiler_output.puts "function #{name} #{n_locals}"
  end

  def write_return
    @compiler_output.puts 'return'
  end

  private

  def print_segment(segment)
    case segment
    when 'var'
      'local'
    when 'arg'
      'argument'
    when 'field'
      'this'
    else
      segment
    end
  end
end
