module RGen::RegisterMap
  class GenericMap
    require_relative 'generic_map/sheet'
    require_relative 'generic_map/cell'

    def initialize(file)
      @file   = file
      @sheets = {}
    end

    attr_reader :file

    def [](sheet_name_or_index)
      case sheet_name_or_index
      when String
        @sheets[sheet_name_or_index]  ||= Sheet.new(file, sheet_name_or_index)
      when Integer
        sheets[sheet_name_or_index]
      end
    end

    def []=(sheet_name, table)
      @sheets[sheet_name] = Sheet.new(file, sheet_name)
      table.each_with_index do |values, row|
        values.each_with_index do |value, column|
          @sheets[sheet_name][row, column]  = value
        end
      end
    end

    def sheets
      @sheets.values
    end
  end
end
