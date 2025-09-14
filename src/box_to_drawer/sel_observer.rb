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
        class << self
            attr_accessor :_instance
        end

        self._instance = nil

        class SelObserver < Sketchup::SelectionObserver
            include Singleton
            def initialize
                super()
                Sketchup.active_model.selection.add_observer(self)
                @running = false
            end

            def start
                return if @running
                Sketchup.active_model.selection.add_observer(self)
                @running = true
            end

            def stop
                    return unless @running
                    Sketchup.active_model.selection.remove_observer(self)
                    @running = false
            end


            #def onSelectionBulkChange(selection)
            #    # Get the model's selection
            #    drawerable_group_count = 0
            #    model = Sketchup.active_model
            #    model.selection.each do |e|
            #        next unless DimensionsDialog::add_selected_group_data(e) || BoxShape::BoxMap.is_xyz_aligned_box?(e)
            #        DimensionsDialog::DimensionsInputs::show
            #        drawerable_group_count += 1
            #    end
            #    DimensionsDialog::close unless drawerable_group_count
            #end

            def onSelectionCleared(selection)
                DimensionsDialog::close
            end


        end # class SelObserver

        def self.quit
            return unless self._instance
            self._instance.stop
            self._instance = nil
        end

        def self.install
            return if self._instance
            self._instance = SelObserver.instance
            self._instance.start
        end
    end #module SelectObserver
end # module AdamExtensions
