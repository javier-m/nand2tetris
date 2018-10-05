class SymbolTable

  attr_reader :class_scope_table, :subroutine_scope_table

  def initialize
    @class_scope_table = []
    @subroutine_scope_table = []
  end

  def start_subroutine
    @subroutine_scope_table = []
  end

  def define_identifier(attr)
    name = attr[:name]
    type = attr[:type]
    kind = attr[:kind]
    if kind == 'static' || kind == 'field'
      @class_scope_table << { name: name, type: type, kind: kind, index: var_count(kind) }
    elsif kind == 'arg' || kind == 'var'
      @subroutine_scope_table << { name: name, type: type, kind: kind, index: var_count(kind) }
    end
  end

  def var_count(kind)
    scope_table = case kind
      when 'static'
        @class_scope_table
      when 'field'
        @class_scope_table
      when 'arg'
        @subroutine_scope_table
      when 'var'
        @subroutine_scope_table
      end
    scope_table.count { |identifier| identifier[:kind] == kind }
  end

  def kind_of(name)
    class_identifier = @class_scope_table.find { |identifier| identifier[:name] == name }
    subroutine_identifier = @subroutine_scope_table.find { |identifier| identifier[:name] == name }
    identifier = class_identifier || subroutine_identifier
    return 'none' if identifier.nil?
    identifier[:kind]
  end

  def type_of(name)
    class_identifier = @class_scope_table.find { |identifier| identifier[:name] == name }
    subroutine_identifier = @subroutine_scope_table.find { |identifier| identifier[:name] == name }
    identifier = class_identifier || subroutine_identifier
    identifier[:type]
  end

  def index_of(name)
    class_identifier = @class_scope_table.find { |identifier| identifier[:name] == name }
    subroutine_identifier = @subroutine_scope_table.find { |identifier| identifier[:name] == name }
    identifier = class_identifier || subroutine_identifier
    identifier[:index]
  end

  def shift_arg_index
    @subroutine_scope_table.map! do |identifier|
        identifier[:index] += 1 if identifier[:kind] == 'arg'
        identifier
      end
  end
end
