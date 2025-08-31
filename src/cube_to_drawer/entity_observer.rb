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
                super
            end
        end # class EntityObserver

    end #module EntityObserver
end # module AdamExtensions

