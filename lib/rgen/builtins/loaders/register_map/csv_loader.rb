RGen.loader(:register_map, [:csv, :tsv]) do
  require 'csv'

  def load_file(file)
    create_map(file) do |map|
      sheet_name      = File.basename(file, '.*')
      map[sheet_name] = CSV.read(file, col_sep: separator(file))
    end
  end

  def separator(file)
    (File.ext(file) == "csv") ? "," : "\t"
  end
end
