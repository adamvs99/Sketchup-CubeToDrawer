#
#  sel_observer.rb
#
#
#  Created by Adam Silver on 08/14/25.
#  copyright Adam Silver © 2025 all rights reserved

require 'sketchup.rb'
require 'singleton'
require_relative 'drawer'
require_relative 'units_dialog'


module AdamExtensions
    module SelectObserver

        class SelObserver < Sketchup::SelectionObserver
            include Singleton
            def initialize
                super()
                Sketchup.active_model.selection.add_observer(self)
            end

            def onSelectionBulkChange(selection)
                # Get the model's selection
                model = Sketchup.active_model
                model.selection.each do |e|
                    next unless UnitsDialog::add_unique_selected_drawer_data(e)
                    UnitsDialog::show
                end
            end

        end # class SelObserver

        def self.install
            SelObserver.instance
        end
    end #module SelectObserver
end # module AdamExtensions
