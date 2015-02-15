class RGen::RegisterMap::GenericMap
  class Sheet
    def initialize(file, name)
      @file = file
      @name = name
      @rows = []
    end

    attr_reader :name
    attr_reader :rows

    def [](row, column)
      rows[row]         ||= []
      rows[row][column] ||= create_cell(row, column)
    end

    def []=(row, column, value)
      self[row, column].value = value
    end

    private

    def create_cell(row, column)
      RGen::RegisterMap::GenericMap::Cell.new(@file, name, row, column)
    end
  end
end
