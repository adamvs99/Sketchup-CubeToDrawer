# frozen_string_literal: true
require_relative 'drawer'
require_relative 'rectangle'

module AdamExtensions

    module Drawer
        class SimplePlusDrawer < Drawer
            def initialize(box_group)
                super(box_group)
            end

            protected
            
            def _create_bottom_panel(data)
                # gate this function if object not valid
                return unless valid?
                model = Sketchup.active_model
                bottom_rect_offset = -data[:sheet_thickness] + data[:dado_thickness]
                bottom_rect = @face_map.to_rect_copy("bottom", 0, 0, data[:sheet_thickness])
                bottom_rect.symetrically_expand(bottom_rect_offset)
                bottom_rect.change_edge("back", bottom_rect_offset.abs)
                model.start_operation("Create Drawer Bottom Group", true)
                bottom_group = model.entities.add_group
                bottom_face = bottom_group.entities.add_face(bottom_rect.points)
                bottom_face.reverse! if bottom_face.normal.z > 0
                bottom_face.pushpull(data[:dado_thickness])
                @current_groups << bottom_group
                model.commit_operation
            end #_create_bottom_panel

            def _create_left_right_panels(data)
                # gate this function if object not valid
                return unless valid?

                model = Sketchup.active_model
                side_rect = @face_map.to_rect_copy("right")
                model.start_operation("Create Drawer Side Group", true)
                right_side_group = model.entities.add_group
                side_face = right_side_group.entities.add_face(side_rect.points)
                side_face.reverse! if side_face.normal.z > 0
                side_face.pushpull(data[:sheet_thickness])
                model.commit_operation
                # cut the bottom dado
                origin = Geom::Point3d.new(side_rect.min_x - data[:sheet_thickness] - data[:dado_depth],
                                           side_rect.min_y - data[:dado_thickness],
                                           side_rect.min_z + data[:sheet_thickness] - data[:dado_thickness])
                cut_rect = GeoUtil::WDHRect.new(origin, data[:dado_depth] * 2, 0, data[:dado_thickness])
                cut_length = side_rect.depth + data[:sheet_thickness]
                # cut bottom dado
                model.start_operation("Side Right Bottom Dado", true)
                right_side_group = Utils.cut_channel(model, right_side_group, cut_rect, cut_length, "y", "lt")
                @current_groups << Utils.copy_move_rotate_group(right_side_group, -@face_map.width + data[:sheet_thickness], 0, 0, Z_AXIS, 180)
                model.commit_operation

                @current_groups << right_side_group
            end # def create_side_panels

            def _create_front_back_panels(data)
                # gate this function if object not valid
                return unless valid?
                sheet_thickness, dado_thickness, dado_depth = [data[:sheet_thickness],
                                                               data[:dado_thickness],
                                                               data[:dado_depth]]
                model = Sketchup.active_model
                base_rect = @face_map.to_rect_copy("front")
                # calculate pocket hole Z positions

                front_rect = base_rect.copy()
                model.start_operation("Create front Panel", true)
                front_rect.expand(-sheet_thickness, 0, 0)
                front_group = model.entities.add_group
                front_face = front_group.entities.add_face(front_rect.points)
                front_face.reverse! if front_face.normal.y < 0
                front_face.pushpull(sheet_thickness)
                model.commit_operation  # Create Front Panel

                # for the back panel need to copy, move, and flip
                # then reduce the bottom face by the sheet thickness
                back_group = Utils.copy_move_rotate_group(front_group, 0, @face_map.depth - sheet_thickness, 0, Z_AXIS, 180)
                bottom_face = BoxShape::BoxMap.find_face("bottom", back_group)
                bottom_face.reverse! if bottom_face.normal.z > 0
                bottom_face.pushpull(-sheet_thickness)
                @current_groups << back_group

                # now slice the bottom dado
                model.start_operation("Slice Bottom Dado", true)
                # cut the bottom dado
                origin = Geom::Point3d.new(base_rect.max_x,
                                           base_rect.min_y + sheet_thickness - dado_depth,
                                           base_rect.min_z + sheet_thickness - dado_thickness)
                cut_rect = GeoUtil::WDHRect.new(origin, 0, dado_depth * 2, dado_thickness)
                cut_length = base_rect.width + sheet_thickness
                @current_groups << Utils.cut_channel(model, front_group, cut_rect, cut_length, "x")
                model.commit_operation  # Create Front Panel

            end # def create_side_front_back_panels

        end # class SimplePlusDrawer
    end # module Drawer
end # module AdamExtensions

