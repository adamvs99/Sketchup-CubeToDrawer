#
#  entity_observer.rb
#
#
#  Created by Adam Silver on 8/28/25.
#  copyright Adam Silver © 2025 all rights reserved

require 'sketchup.rb'

module AdamExtensions
    module EntityObserver
        class EntityObserver < Sketchup::EntitiesObserver
            def onElementRemoved(entities, entity_id)
                # Forward to your app logic or add a small trace to debug.
                # Example: AdamExtensions::Logger.debug("Removed entity_id=#{entity_id}")
                # NOTE: You can't get the removed entity from entity_id reliably here.
            end
        end # class EntityObserver

    end #module EntityObserver
end # module AdamExtensions

