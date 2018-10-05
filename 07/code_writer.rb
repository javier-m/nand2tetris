class CodeWriter
  def initialize(output_filename)
    @output_file = File.new(output_filename, 'w')
    @eq_index = 0
    @gt_index = 0
    @lt_index = 0
  end

  def set_filename(filename)
    @filename = filename
  end

  def write_arithmetic(command)
    case command
    when 'add'
      load_stack_value_on_D # D=y
      decrement_stack
      load_stack_value_on_M # M=x
      @output_file.puts "M=D+M" # M=x+y
    when 'sub'
      load_stack_value_on_D # D=y
      decrement_stack
      load_stack_value_on_M # M=x
      @output_file.puts "M=M-D" # M=x-y
    when 'neg'
      load_stack_value_on_M # M=x
      @output_file.puts "M=-M" # M=-x
    when 'eq'
      load_stack_value_on_D # D=y
      decrement_stack
      load_stack_value_on_M # M=x
      @output_file.puts "D=M-D" # D=x-y
      @output_file.puts "@EQ_#{@eq_index}"
      @output_file.puts "D;JEQ" # if D<> 0 GOTO EQ_xx
      @output_file.puts "D=0"
      @output_file.puts "@EQ_#{@eq_index}_JUMP"
      @output_file.puts "0;JMP"
      @output_file.puts "(EQ_#{@eq_index})"
      @output_file.puts "D=-1"
      @output_file.puts "(EQ_#{@eq_index}_JUMP)"
      @eq_index += 1
      load_D_on_M # M= (x<>y)
    when 'gt'
      load_stack_value_on_D # D=y
      decrement_stack
      load_stack_value_on_M # M=x
      @output_file.puts "D=M-D" # D=x-y
      @output_file.puts "@GT_#{@gt_index}"
      @output_file.puts "D;JGT" # if D>0 GOTO GT_xx
      @output_file.puts "D=0"
      @output_file.puts "@GT_#{@gt_index}_JUMP"
      @output_file.puts "0;JMP"
      @output_file.puts "(GT_#{@gt_index})"
      @output_file.puts "D=-1"
      @output_file.puts "(GT_#{@gt_index}_JUMP)"
      @gt_index += 1
      load_D_on_M # M= (x>y)
    when 'lt'
      load_stack_value_on_D # D=y
      decrement_stack
      load_stack_value_on_M # M=x
      @output_file.puts "D=M-D" # D=x-y
      @output_file.puts "@LT_#{@lt_index}"
      @output_file.puts "D;JLT" # if D<0 GOTO LT_xx
      @output_file.puts "D=0"
      @output_file.puts "@LT_#{@lt_index}_JUMP"
      @output_file.puts "0;JMP"
      @output_file.puts "(LT_#{@lt_index})"
      @output_file.puts "D=-1"
      @output_file.puts "(LT_#{@lt_index}_JUMP)"
      @lt_index += 1
      load_D_on_M # M= (x<y)
    when 'and'
      load_stack_value_on_D # D=y
      decrement_stack
      load_stack_value_on_M # M=x
      @output_file.puts "M=D&M" # M=x&y
    when 'or'
      load_stack_value_on_D # D=y
      decrement_stack
      load_stack_value_on_M # M=x
      @output_file.puts "M=D|M" # M=x|y
    when 'not'
      load_stack_value_on_M # M=x
      @output_file.puts "M=!M" # M=!x
    end
  end

  def write_push_pop(command, segment, index)
    if command == 'push' && segment == 'constant'
      push_segment_address_on_stack(segment, index)
    else
      case command
      when 'push'
        push_segment_address_on_stack(segment, index) # M=segment[index]
        @output_file.puts 'A=M' # M= RAM[Segment[index]]
        @output_file.puts 'D=M' # D= RAM[Segment[index]]
        decrement_stack # does not change D
        push_D_on_stack
      when 'pop'
        push_segment_address_on_stack(segment, index) # M=segment[index]
        @output_file.puts 'D=M' # D= Segment[index] segment address
        @output_file.puts '@13'
        @output_file.puts 'M=D' # R[13]= segment[index]
        decrement_stack
        load_stack_value_on_M # M = value to be popped
        @output_file.puts 'D=M' # D= value to be popped
        @output_file.puts '@13'
        @output_file.puts 'A=M' # A is the segment address (pointer)
        @output_file.puts 'M=D' # RAM[segment address] = value to be popped
        decrement_stack
      end
    end
  end

  def close
    @output_file.close
  end

  private

  def increment_stack
    @output_file.puts "@SP"
    @output_file.puts 'M=M+1'
  end

  def decrement_stack
    @output_file.puts "@SP"
    @output_file.puts 'M=M-1'
  end

  def load_stack_value_on_M
    @output_file.puts "@SP"
    @output_file.puts "A=M-1"
  end

  def load_stack_value_on_D
    load_stack_value_on_M
    @output_file.puts "D=M"
  end

  def load_D_on_M
    load_stack_value_on_M
    @output_file.puts "M=D"
  end

  def push_D_on_stack
    @output_file.puts '@SP'
    @output_file.puts 'A=M'
    @output_file.puts 'M=D'
    increment_stack
  end

  def push_constant_on_stack(index)
    if index[0] == '-'
      @output_file.puts "@#{2**15 + index.to_i}"
    else
      @output_file.puts "@#{index}"
    end
    @output_file.puts 'D=A'
    push_D_on_stack
  end

  def push_segment_address_on_stack_from_index(index)
    # D contains the base address
    push_D_on_stack # x= base address
    push_constant_on_stack(index) # y= index
    write_arithmetic('add') # StackValue (on M) = base + index
  end

  def push_segment_address_on_stack(segment, index)
    # increment the stack
    # print:
    # - A is the pointer the address OR the value of the constant
    # - M is the value of the stack
    case segment
    when 'constant'
      push_constant_on_stack(index)
    when 'local'
      @output_file.puts '@LCL'
      @output_file.puts 'D=M' # D= base address
      push_segment_address_on_stack_from_index(index)
    when 'argument'
      @output_file.puts '@ARG'
      @output_file.puts 'D=M' # D= base address
      push_segment_address_on_stack_from_index(index)
    when 'this'
      @output_file.puts '@THIS'
      @output_file.puts 'D=M' # D= base address
      push_segment_address_on_stack_from_index(index)
    when 'that'
      @output_file.puts '@THAT'
      @output_file.puts 'D=M' # D= base address
      push_segment_address_on_stack_from_index(index)
    when 'temp'
      @output_file.puts "@#{5+index.to_i}"
      @output_file.puts 'D=A' # D= base address
      push_D_on_stack # x= base address
      load_stack_value_on_M
    when 'pointer'
      @output_file.puts "@#{3+index.to_i}"
      @output_file.puts 'D=A' # D= base address
      push_D_on_stack # x= base address
      load_stack_value_on_M
    when 'static'
      @output_file.puts "@#{@filename}.#{index}"
      @output_file.puts 'D=A' # D= base address
      push_D_on_stack # x= base address
      load_stack_value_on_M
    end
  end
end
