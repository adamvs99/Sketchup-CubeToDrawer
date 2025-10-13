#
#  simple_drawer.rb
#
#
#  Created by Adam Silver on 10/5/25.
#  copyright Adam Silver © 2025 all rights reserved

require_relative 'drawer'
require_relative 'rectangle'


module AdamExtensions

    module Drawer
        class SimpleDrawer < Drawer
            def initialize(box_group)
                super(box_group)
            end

            protected

            def _create_bottom_panel(data)
                # gate this function if object not valid
                return unless valid?
                sheet_thickness, dado_thickness, dado_depth, hidden_dado = [data[:sheet_thickness],
                                                                            data[:dado_thickness],
                                                                            data[:dado_depth],
                                                                            data["hidden_dado"]]
                model = Sketchup.active_model
                bottom_rect = @face_map.to_rect_copy("bottom", 0, 0, sheet_thickness)
            end #_create_bottom_panel

            def _create_left_right_panels(data)
                # gate this function if object not valid
                return unless valid?
                sheet_thickness, dado_thickness, dado_depth, hidden_dado = [data[:sheet_thickness],
                                                                            data[:dado_thickness],
                                                                            data[:dado_depth],
                                                                            data["hidden_dado"]]

                side_rect = @face_map.to_rect_copy("right")

                # create a face of the cut elongated box item just back of the 'front' of the initial box
                model = Sketchup.active_model
            end # def create_side_panels

            def _create_front_back_panels(data)
                # gate this function if object not valid
                return unless valid?
                sheet_thickness, dado_thickness, dado_depth, hidden_dado = [data[:sheet_thickness],
                                                                            data[:dado_thickness],
                                                                            data[:dado_depth],
                                                                            data["hidden_dado"]]
                model = Sketchup.active_model
                base_rect = @face_map.to_rect_copy("front")

            end # def create_side_front_back_panels

        end #class SimpleDrawer
    end # module Drawer
end # module AdamExtensions

