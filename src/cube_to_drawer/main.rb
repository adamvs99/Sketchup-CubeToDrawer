#
#  main.rb
#
#
#  Created by Adam Silver on 7/16/25.
#  copyright Adam Silver © 2025 all rights reserved

require 'sketchup.rb'
require 'extensions.rb'
require_relative 'cubic_shape'
require_relative 'rectangle'
require_relative 'utils'
require_relative 'units'
require_relative 'units_dialog'
require_relative 'sel_observer'
require 'pp'

module AdamExtensions

    module CubeToDrawer


        #-------------------------------------------------------------------------------
        #  main Module code....
        #-------------------------------------------------------------------------------
        def self.ctd_main
            Units::set_units_type
            sel = Sketchup.active_model.selection
            return unless sel.length==1
            self._drawer = Drawer::Drawer.new(sel[0])
            self._drawer.update_sheet_dado_values()
            return unless self._drawer&.valid?
            sel.clear
            UnitsDialog.show
            SelectObserver.install
            self.update
        end # def ctd_main

        unless file_loaded(__FILE__)
            menu = UI.menu("Extensions").add_item("Cube to Drawer") { self.ctd_main }
            file_loaded(__FILE__)
        end

    end # module CubeToDrawer
end # module AdamExtensions
