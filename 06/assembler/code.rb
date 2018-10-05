class Code
  def self.dest(dest)
    case dest
    when 'M'
      return '001'
    when 'D'
      return '010'
    when 'MD'
      return '011'
    when 'A'
      return '100'
    when 'AM'
      return '101'
    when 'AD'
      return '110'
    when 'AMD'
      return '111'
    else
      return '000'
    end
  end

  def self.comp(comp)
    comp_noM = comp.gsub(/M/, 'A')
    comp_binary = case comp_noM
    when '0'
      '0101010'
    when '1'
      '0111111'
    when '-1'
      '0111010'
    when 'D'
      '0001100'
    when 'A'
      '0110000'
    when '!D'
      '0001101'
    when '!A'
      '0110001'
    when '-D'
      '0001111'
    when '-A'
      '0110011'
    when 'D+1'
      '0011111'
    when 'A+1'
      '0110111'
    when 'D-1'
      '0001110'
    when 'A-1'
      '0110010'
    when 'D+A'
      '0000010'
    when 'D-A'
      '0010011'
    when 'A-D'
      '0000111'
    when 'D&A'
      '0000000'
    when 'D|A'
      '0010101'
    end
    comp_binary[0] = '1' if comp =~ /M/
    return comp_binary
  end

  def self.jump(jump)
    case jump
    when 'JGT'
      return '001'
    when 'JEQ'
      return '010'
    when 'JGE'
      return '011'
    when 'JLT'
      return '100'
    when 'JNE'
      return '101'
    when 'JLE'
      return '110'
    when 'JMP'
      return '111'
    else
      return '000'
    end
  end
end
