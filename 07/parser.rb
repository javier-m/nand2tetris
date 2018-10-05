require_relative 'command_types'

class Parser
  ARITHMETIC_COMMANDS = %(add sub neg eq gt lt and or not)

  attr_reader :filename, :lines, :current_line

  def initialize(input_file)
    @filename = input_file.match(/(?<filename>\w+)\.vm$/)[:filename]
    @lines = File.read(input_file)
      .split(/$/)
      .map { |line| line.gsub(/^\s+/, '')
        .gsub(/\s+$/, '')
        .gsub(/\/\/.*$/, '') }
      .reject { |line| line.empty? }
    @current_line = -1
  end

  def has_more_commands?
    @current_line < @lines.length - 1
  end

  def advance
    @current_line += 1
  end

  def command_type
    first_word = @lines[current_line].split(' ')[0]
    case first_word
    when 'push'
      return C_PUSH
    when 'pop'
      return C_POP
    else
      return C_ARITHMETIC if ARITHMETIC_COMMANDS.include? first_word
    end
  end

  def arg1
    raise "wrong command type" if command_type == C_RETURN
    @lines[current_line].split(' ')[0]
  end

  def arg2
    raise "wrong command type" unless [C_PUSH, C_POP, C_FUNCTION, C_CALL].include? command_type
    @lines[current_line].split(' ')[1]
  end

  def arg3
    raise "wrong command type" unless [C_PUSH, C_POP, C_FUNCTION, C_CALL].include? command_type
    @lines[current_line].split(' ')[2]
  end
end
