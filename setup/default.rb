enable :global        , [:data_width, :address_width]
enable :register_block, [:name, :byte_size]
enable :register      , [:offset_address, :name, :accessibility]
enable :bit_field     , [:bit_assignment, :name, :type, :initial_value, :reference]
enable :bit_field     , :type, [:rw, :ro, :reserved]
enable :register_block, [:module_declaration, :port_declarations, :signal_declarations, :clock_reset, :host_if, :response_mux]
enable :register_block, :host_if, [:apb]
enable :register      , [:address_decoder, :read_data]