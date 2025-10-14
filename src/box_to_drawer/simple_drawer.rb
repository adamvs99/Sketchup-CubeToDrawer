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
                model = Sketchup.active_model
                bottom_rect = @face_map.to_rect_copy("bottom")
                model.start_operation("Create Drawer Bottom Group", true)
                bottom_group = model.entities.add_group
                bottom_face = bottom_group.entities.add_face(bottom_rect.points)
                bottom_face.reverse! if bottom_face.normal.z < 0
                bottom_face.pushpull(data[:dado_thickness])
                @current_groups << bottom_group
                model.commit_operation
            end #_create_bottom_panel

            def _create_left_right_panels(data)
                # gate this function if object not valid
                return unless valid?

                model = Sketchup.active_model
                side_rect = @face_map.to_rect_copy("right")
                side_rect.change_edge("bottom", data[:dado_thickness])
                model.start_operation("Create Drawer Side Group", true)
                right_side_group = model.entities.add_group
                side_face = right_side_group.entities.add_face(side_rect.points)
                side_face.reverse! if side_face.normal.z > 0
                side_face.pushpull(data[:sheet_thickness])
                @current_groups << right_side_group
                model.commit_operation

                @current_groups << Utils.copy_move_rotate_group(right_side_group, -@face_map.width + data[:sheet_thickness], 0, 0, Z_AXIS, 180)
            end # def create_side_panels

            def _create_front_back_panels(data)
                # gate this function if object not valid
                return unless valid?
                model = Sketchup.active_model
                front_rect = @face_map.to_rect_copy("front")
                front_rect.expand(-data[:sheet_thickness])
                front_rect.change_edge("bottom", data[:dado_thickness])
                model.start_operation("Create Drawer Front Group", true)
                front_side_group = model.entities.add_group
                front_face = front_side_group.entities.add_face(front_rect.points)
                front_face.reverse! if front_face.normal.z < 0
                front_face.pushpull(data[:sheet_thickness])
                @current_groups << front_side_group
                model.commit_operation

                @current_groups << Utils.copy_move_rotate_group(front_side_group, 0, @face_map.depth - data[:sheet_thickness], 0, Z_AXIS, 180)
            end # def create_side_front_back_panels

        end #class SimpleDrawer
    end # module Drawer
end # module AdamExtensions

