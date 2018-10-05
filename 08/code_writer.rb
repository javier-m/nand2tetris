class CodeWriter
  def initialize(output_filename)
    @output_file = File.new(output_filename, 'w')
    @eq_index = 0
    @gt_index = 0
    @lt_index = 0
  end

  def set_filename(filename)
    @filename = filename
    @current_function_name = 'null'
  end

  def write_init
    # stack initialization
    @output_file.puts "@256"
    @output_file.puts "D=A"
    @output_file.puts "@SP"
    @output_file.puts "M=D"
    @current_function_name = "null"
    @nb_returns = 0

    # call Sys.init
    write_call('Sys.init', '0')

  end

  def write_label(label)
    # label within a function
    @output_file.puts "(#{@current_function_name}$#{label})"
  end

  def write_goto(label)
    # goto label within a function
    @output_file.puts "@#{@current_function_name}$#{label}"
    @output_file.puts "0;JMP"
  end

  def write_if(label)
    # if-goto label within a function
    load_stack_value_on_D # D=y
    decrement_stack
    @output_file.puts "@#{@current_function_name}$#{label}"
    @output_file.puts "D;JNE"
  end

  def write_call(function_name, arg_numbers)
    # push caller context on stack
    # 1. push return address
    @nb_returns += 1
    @output_file.puts "@#{@current_function_name}$return_#{@nb_returns}"
    @output_file.puts "D=A"
    push_D_on_stack

    # 2. save LCL of the calling function
    push_segment_base_address_on_stack('local')

    # 3. save ARG of the calling function
    push_segment_base_address_on_stack('argument')

    # 4. save THIS of the calling function
    push_segment_base_address_on_stack('this')

    # 5. save THAT of the calling function
    push_segment_base_address_on_stack('that')

    # 6. ARG = SP-n-5 reposition ARG where n is number of args
    @output_file.puts "@SP"
    @output_file.puts "D=M"
    push_D_on_stack
    push_constant_on_stack("#{arg_numbers.to_i + 5}")
    write_arithmetic('sub')
    load_stack_value_on_D
    decrement_stack
    @output_file.puts "@ARG"
    @output_file.puts "M=D"

    # 7. LCL = SP reposition LCL
    @output_file.puts "@SP"
    @output_file.puts "D=M"
    @output_file.puts "@LCL"
    @output_file.puts "M=D"

    # 8. goto called function
    @output_file.puts "@#{function_name}"
    @output_file.puts "0;JMP"

    # 9. declare label for the return address
    write_label("return_#{@nb_returns}")
  end

  def write_function(function_name, lcl_numbers)
    @current_function_name = function_name
    @nb_returns = 0
    @output_file.puts "(#{function_name})"
    lcl_numbers.to_i.times do |i|
      push_constant_on_stack('0')
    end
  end

  def write_return
    # R13 = FRAME = LCL
    @output_file.puts "@LCL"
    @output_file.puts "D=M"
    @output_file.puts "@R14"  # R14 = FRAME - not R13 because pop use it
    @output_file.puts "M=D"

    # R15 = return address RET = *(FRAME - 5) - not R13 because pop use it
    assign_offset_memory_value_to_memory('R14', '5', 'R15')

    # *ARG = pop() assign the returned value on top of stack of the caller
    write_push_pop('pop', 'argument', '0')

    # SP = ARG + 1 restore SP for the caller - store it in R13 (pop not used any longer)
    push_segment_address_on_stack('argument', '1')
    load_stack_value_on_D
    decrement_stack
    @output_file.puts "@R13"
    @output_file.puts "M=D"

    # THAT = *(FRAME - 1)
    assign_offset_memory_value_to_memory('R14', '1', 'THAT')

    # THIS = *(FRAME - 2)
    assign_offset_memory_value_to_memory('R14', '2', 'THIS')

    # ARG = *(LCL - 3)
    assign_offset_memory_value_to_memory('R14', '3', 'ARG')

    # LCL = *(LCL - 4)
    assign_offset_memory_value_to_memory('R14', '4', 'LCL')

    # SP = R15
    @output_file.puts "@R13" # R13 = SP after return
    @output_file.puts "D=M"
    @output_file.puts "@SP"
    @output_file.puts "M=D"

    # goto return address
    @output_file.puts "@R15" # RET = *R15
    @output_file.puts "A=M"
    @output_file.puts "0;JMP"
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

  def push_segment_base_address_on_stack(segment)
    # increment the stack
    # print:
    # - A is the pointer the address OR the value of the constant
    # - M is the value of the stack
    case segment
    when 'local'
      @output_file.puts '@LCL'
      @output_file.puts 'D=M' # D= base address
      push_D_on_stack
    when 'argument'
      @output_file.puts '@ARG'
      @output_file.puts 'D=M' # D= base address
      push_D_on_stack
    when 'this'
      @output_file.puts '@THIS'
      @output_file.puts 'D=M' # D= base address
      push_D_on_stack
    when 'that'
      @output_file.puts '@THAT'
      @output_file.puts 'D=M' # D= base address
      push_D_on_stack
    end
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

  def assign_offset_memory_value_to_memory(origin_memory, offset_to_frame, destination_memory)
    @output_file.puts "@#{origin_memory}"
    @output_file.puts "D=M"
    push_D_on_stack
    push_constant_on_stack(offset_to_frame)
    write_arithmetic('sub')
    load_stack_value_on_D
    decrement_stack
    @output_file.puts "A=D"
    @output_file.puts "D=M"
    @output_file.puts "@#{destination_memory}" # TEMP[xx]
    @output_file.puts "M=D"
  end
end
