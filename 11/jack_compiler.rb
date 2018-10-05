require 'pry-byebug'
require_relative 'jack_tokenizer'
require_relative 'compilation_engine'
require_relative 'symbol_table'

def jack_compiler(input_stream)

  # create tokenizers
  tokenizers = []
  directory_path = nil
  if input_stream =~ /\.jack$/ # the argument is a jack file
    tokenizers[0] = JackTokenizer.new({filename: input_stream, directory: nil})
  else # the argument is a folder containing jack files
    Dir["#{input_stream}/*.jack"].each_with_index do |input_filepath, index|
      filename = input_filepath.match(/(?<filename>\w+\.jack$)/)[:filename]
      tokenizers[index] = JackTokenizer.new({filename: filename, directory: input_stream})
    end
  end

  tokenizers.each do |tokenizer|
    # tokenize file
    tokenizer.tokenize

    # create output file
    compiler_output = File.new("#{tokenizer.directory}/#{tokenizer.filename}.vm", 'w')

    # parse file
    compilation_engine = CompilationEngine.new(compiler_output, tokenizer)
    compilation_engine.compile

    # close output file
    compiler_output.close
  end
end

jack_compiler(ARGV[0])
