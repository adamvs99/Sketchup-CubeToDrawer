#
#  sel_observer.rb
#
#
#  Created by Adam Silver on 08/14/25.
#  copyright Adam Silver © 2025 all rights reserved

require 'sketchup.rb'
require 'singleton'
require_relative 'drawer'
require_relative 'dimensions_dialog'


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
                drawerable_group_count = 0
                model = Sketchup.active_model
                model.selection.each do |e|
                    next unless DimensionsDialog::add_selected_group_data(e) || BoxShape::BoxMap.is_xyz_aligned_box?(e)
                    DimensionsDialog::show
                    drawerable_group_count += 1
                end
                DimensionsDialog::close if drawerable_group_count == 0
            end

        end # class SelObserver

        def self.install
            SelObserver.instance
        end
    end #module SelectObserver
end # module AdamExtensions
