require 'pry-byebug'
require_relative 'parser'
require_relative 'symbol-table'

def assembler (input_text)
  symbol_table = SymbolTable.new
  parser = Parser.new(input_text)

  # first pass: collect all labels (pseudo command symbols) and their ROM location
  program_lines_counter = -1
  while parser.hasMoreCommands?
    parser.advance
    commandType = parser.commandType
    if commandType == C_COMMAND || commandType == A_COMMAND
      program_lines_counter += 1
    elsif commandType == L_COMMAND
      label = parser.symbol
      symbol_table.addEntry(label, program_lines_counter + 1)
    end
  end

  # second pass: parse commands and build output
  output_binary = []
  parser.reinitialize
  next_available_RAM_slot = 16;
  while parser.hasMoreCommands?
    parser.advance
    commandType = parser.commandType
    if commandType == C_COMMAND
      comp_binary = Code.comp(parser.comp)
      dest_binary = Code.dest(parser.dest)
      jump_binary = Code.jump(parser.jump)
      output_binary.push "111#{comp_binary}#{dest_binary}#{jump_binary}"
    elsif commandType == A_COMMAND
      symbol = parser.symbol
      # if the symbol is a variable
      # i.e. if it is not a pseudo command (not included in the symbol_table)
      # and if it is not an integer
      unless (symbol_table.contains? symbol) || symbol.to_i.to_s == symbol
        symbol_table.addEntry(symbol, next_available_RAM_slot)
        next_available_RAM_slot += 1
      end
      # convert symbol in 16 bits
      output_binary.push sprintf "%016b", symbol_table.getAddress(symbol)
    end
  end

  output_binary.join("\n")
end

input_text = File.read(ARGV[0])
puts output_text = assembler(input_text)
File.write(ARGV[0].gsub(/\.asm$/, '_own.hack'), output_text)
