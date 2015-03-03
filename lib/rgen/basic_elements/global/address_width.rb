RGen.item(:global, :address_width) do
  configuration do
    field :address_width, default: 32

    build do |width|
      @address_width  = Integer(width)
    end
  end
end
