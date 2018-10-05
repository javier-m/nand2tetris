class SymbolTable
  def initialize
    @symbol_table = {
      'SP' => 0,
      'LCL' => 1,
      'ARG' => 2,
      'THIS' => 3,
      'THAT' => 4,
      'SCREEN' => 16384,
      'KBD' => 24576
    }

    (0..15).each do |index|
      @symbol_table["R#{index}"] = index
    end
  end

  def addEntry(symbol, address)
    @symbol_table[symbol] = address
  end

  def contains?(symbol)
    @symbol_table.key? symbol
  end

  def getAddress(symbol)
    return @symbol_table[symbol] if contains? symbol
    symbol
  end
end
