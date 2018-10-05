require_relative 'command_types'
require_relative 'code'

class Parser
  C_PATTERN = /^((?<dest>[AMD]{1,3})=)?(?<comp>[AMD01\+\-&!\|]{1,3})(;(?<jump>J\w{2}))?$/
  A_PATTERN = /^@(?<symbol>.+)$/
  L_PATTERN = /\((?<symbol>.+)\)$/

  attr_reader :lines, :current_line

  def initialize(input_text)
    @lines = input_text.split(/$/).map { |line| line.gsub(/\s/, '').gsub(/\/\/.*$/, '') }.reject { |line| line.empty? }
    @current_line = -1
  end

  def reinitialize
    @current_line =-1
  end

  def hasMoreCommands?
    @current_line < @lines.length - 1
  end

  def advance
    @current_line += 1
  end

  def commandType
    case @lines[current_line][0]
    when '@'
      return A_COMMAND
    when '('
      return L_COMMAND
    when nil
      return L_COMMAND
    else
      return C_COMMAND
    end
  end

  def symbol
    raise "wrong command type" if commandType == C_COMMAND
    if commandType == A_COMMAND
      @lines[@current_line].match(A_PATTERN)[:symbol]
    elsif commandType == L_COMMAND
      @lines[@current_line].match(L_PATTERN)[:symbol]
    end
  end

  def dest
    raise "wrong command type" if commandType != C_COMMAND
    @lines[@current_line].match(C_PATTERN)[:dest]
  end

  def comp
    raise "wrong command type" if commandType != C_COMMAND
    @lines[@current_line].match(C_PATTERN)[:comp]
  end

  def jump
    raise "wrong command type" if commandType != C_COMMAND
    @lines[@current_line].match(C_PATTERN)[:jump]
  end

end
