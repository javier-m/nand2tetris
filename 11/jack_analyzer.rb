require 'pry-byebug'
require_relative 'jack_tokenizer'
require_relative 'compilation_engine'
require_relative 'symbol_table'

def jack_analyzer(input_stream)

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

    # parse file
    compilation_engine = CompilationEngine.new(tokenizer)
    compilation_engine.compile
  end
end

jack_analyzer(ARGV[0])
