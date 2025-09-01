#
#  sel_observer.rb
#
#
#  Created by Adam Silver on 08/14/25.
#  copyright Adam Silver © 2025 all rights reserved

require 'sketchup.rb'
require_relative 'drawer'
require_relative 'units_dialog'


module AdamExtensions
    module SelectObserver
        class << self
            attr_accessor :_sel_observer
        end
        self._sel_observer = nil

        class SelObserver < Sketchup::SelectionObserver
            def onSelectionBulkChange(selection)
                # Get the model's selection
                model = Sketchup.active_model
                model.selection.each do |e|
                    next unless e.is_a? Sketchup::Group
                    next unless Drawer::Drawer.is_drawer_group? e
                    UnitsDialog::show
                    break
                end
            end

        end # class SelObserver

        def self.install
            # singletonized
            return unless self._sel_observer.nil?
            self._sel_observer = SelObserver.new
            Sketchup.active_model.selection.add_observer(self._sel_observer)
        end
    end #module SelectObserver
end # module AdamExtensions
