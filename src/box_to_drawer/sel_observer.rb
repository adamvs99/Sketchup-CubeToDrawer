#
#  sel_observer.rb
#
#
#  Created by Adam Silver on 08/14/25.
#  copyright Adam Silver © 2025 all rights reserved

require 'sketchup.rb'
require 'singleton'
require 'observer'
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
            include Observable
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


            def onSelectionBulkChange(selection)
                changed
                notify_observers("selection_change", selection)
            end

            def onSelectionRemoved(selection)
                changed
                notify_observers("selection_removed", selection)
            end
            def onSelectionCleared(selection)
                DimensionsDialog::close
            end


        end # class SelObserver

        def self.quit
            return unless self._instance
            self._instance.stop
            self._instance = nil
        end

        def self.instance
            self._instance
        end
        def self.install
            return if self._instance
            self._instance = SelObserver.instance
            self._instance.start
        end
    end #module SelectObserver
end # module AdamExtensions
