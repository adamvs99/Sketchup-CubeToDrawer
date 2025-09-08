#
#  main.rb
#
#
#  Created by Adam Silver on 7/16/25.
#  copyright Adam Silver © 2025 all rights reserved

require 'sketchup.rb'
require 'extensions.rb'
require_relative 'drawer'
require_relative 'units'
require_relative 'dimensions_dialog'
require_relative 'sel_observer'

module AdamExtensions

    module BoxToDrawer


        #-------------------------------------------------------------------------------
        #  main Module code....
        #-------------------------------------------------------------------------------
        def self.ctd_main
            return unless Drawer::Drawer::selection_to_drawers("test")
            Units::set_units_type
            Drawer::Drawer.initialize_units
            DimensionsDialog::show
            SelectObserver::install
        end # def ctd_main

        unless file_loaded(__FILE__)
            menu = UI.menu("Extensions").add_item("Box to Drawer") { self.ctd_main }
            file_loaded(__FILE__)
        end

    end # module BoxToDrawer
end # module AdamExtensions
