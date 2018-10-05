require 'pry-byebug'
require_relative 'parser'
require_relative 'code_writer'

def vm_translator(input_stream)

  # create parsers and code_writer
  parsers = []
  if input_stream =~ /\.vm$/ # the argument is a VM file
    parsers[0] = Parser.new(input_stream)
    output_filename = input_stream.gsub(/\.vm$/, '.asm')
    code_writer = CodeWriter.new(output_filename)
  else # the argument is a folder containing VM files
    Dir["#{input_stream}/*.vm"].each_with_index do |input_file, index|
      parsers[index] = Parser.new(input_file)
    end
    output_filename = input_stream.split('/')[-1]
    output_path = "#{input_stream}/#{output_filename}.asm"
    code_writer = CodeWriter.new(output_path)
  end

  # parse file and convert to assembly
  code_writer.write_init # bootstrap code
  parsers.each do |parser|
    code_writer.set_filename(parser.filename)
    while parser.has_more_commands?
      parser.advance
      command_type = parser.command_type
      if command_type == C_PUSH || command_type == C_POP
        code_writer.write_push_pop(parser.arg1, parser.arg2, parser.arg3)
      elsif command_type == C_LABEL
        code_writer.write_label(parser.arg2)
      elsif command_type == C_GOTO
        code_writer.write_goto(parser.arg2)
      elsif command_type == C_IF
        code_writer.write_if(parser.arg2)
      elsif command_type == C_CALL
        code_writer.write_call(parser.arg2, parser.arg3)
      elsif command_type == C_FUNCTION
        code_writer.write_function(parser.arg2, parser.arg3)
      elsif command_type == C_RETURN
        code_writer.write_return
      elsif command_type == C_ARITHMETIC
        code_writer.write_arithmetic(parser.arg1)
      end
    end
  end
  code_writer.close
end

vm_translator(ARGV[0])
# File.write(ARGV[0].gsub(/\.asm$/, '_own.hack'), output_text)
