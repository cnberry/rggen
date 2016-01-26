module RGen
  module Rtl
    output_component_store :rtl do
      entry do
        component_class   OutputBase::Component
        component_factory OutputBase::ComponentFactory
      end

      entry :register_block do
        component_class   Component
        component_factory OutputBase::ComponentFactory
        item_base         Item
        item_factory      OutputBase::ItemFactory
      end

      entry :register do
        component_class   Component
        component_factory OutputBase::ComponentFactory
        item_base         Item
        item_factory      OutputBase::ItemFactory
      end

      entry :bit_field do
        component_class   Component
        component_factory OutputBase::ComponentFactory
        item_base         Item
        item_factory      OutputBase::ItemFactory
      end

      output_directory  'rtl'
    end
  end
end
