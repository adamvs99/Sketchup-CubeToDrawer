#
#  pocket_screw_drawer.rb
#
#
#  Created by Adam Silver on 10/5/25.
#  copyright Adam Silver © 2025 all rights reserved

require_relative 'drawer'
require_relative 'rectangle'
require_relative 'pocket_screw_group'


module AdamExtensions

    module Drawer
        class PocketScrewDrawer < Drawer
            def initialize(box_group)
                super(box_group)
            end

            protected

            def _create_bottom_panel(data)
                # gate this function if object not valid
                return unless valid?
                sheet_thickness, dado_depth = [data[:sheet_thickness], data[:dado_depth]]
                bottom_upper_shrink = dado_depth-sheet_thickness

                model = Sketchup.active_model
                bottom_rect = @face_map.to_rect_copy("bottom", 0, 0, sheet_thickness)
                bottom_rect.expand(bottom_upper_shrink)
                bottom_rect.change_edge("front", -bottom_upper_shrink)
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
                sheet_thickness, dado_thickness, dado_depth = [data[:sheet_thickness],
                                                               data[:dado_thickness],
                                                               data[:dado_depth]]

                side_rect = @face_map.to_rect_copy("right")
                model = Sketchup.active_model
                model.start_operation("Create Side Right Group", true)
                right_side_group = model.entities.add_group
                side_face = right_side_group.entities.add_face(side_rect.points)
                side_face.reverse! if side_face.normal.x > 0
                side_face.pushpull(sheet_thickness)
                model.commit_operation

                # cut the bottom dado
                origin = Geom::Point3d.new(side_rect.min_x - sheet_thickness - dado_depth,
                                           side_rect.min_y - dado_thickness,
                                           side_rect.min_z + sheet_thickness - dado_thickness)
                cut_rect = GeoUtil::WDHRect.new(origin, dado_depth * 2, 0, dado_thickness)
                cut_length = side_rect.depth+sheet_thickness
                # cut bottom dado
                model.start_operation("Side Right Bottom Dado", true)
                right_side_group = Utils.cut_channel(model, right_side_group, cut_rect, cut_length, "y", "lt")
                model.commit_operation
                # create a copy .. move to left side .. rotate 180 degrees
                @current_groups << right_side_group
                @current_groups << Utils.copy_move_rotate_group(right_side_group, -@face_map.width + sheet_thickness, 0, 0, Z_AXIS, 180)

                # put in pocket screw holes
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
                start_points = _generate_pocket_z_start_pts(base_rect.max_z, base_rect.height - sheet_thickness)

                front_rect = base_rect.copy()
                model.start_operation("Create front Panel", true)
                front_rect.expand(-sheet_thickness, 0, 0)
                front_group = model.entities.add_group
                front_face = front_group.entities.add_face(front_rect.points)
                front_face.reverse! if front_face.normal.y < 0
                front_face.pushpull(sheet_thickness)
                model.commit_operation  # Create Front Panel

                model.start_operation("Slice Bottom Dado", true)
                # cut the bottom dado
                origin = Geom::Point3d.new(base_rect.max_x,
                                           base_rect.min_y + sheet_thickness - dado_depth,
                                           base_rect.min_z + sheet_thickness - dado_thickness)
                cut_rect = GeoUtil::WDHRect.new(origin, 0, dado_depth * 2, dado_thickness)
                cut_length = base_rect.width + sheet_thickness
                front_group = Utils.cut_channel(model, front_group, cut_rect, cut_length, "x")
                model.commit_operation  # Create Front Panel
                model.start_operation("Cut Pocket Holes", true)
                @current_groups << _cut_pocket_holes(model, front_group, front_rect, "front", start_points)
                model.commit_operation  # Create Front Panel

            end # def create_side_front_back_panels

            private

            def _generate_pocket_z_start_pts(z_mx, z_distance)
                start_points = []
                if z_distance <= 3.0
                    start_points << z_mx - z_distance / 2.0
                elsif z_distance <= 4.0
                    start_points << z_mx - 1.0
                    start_points << z_mx - z_distance + 1.0
                else z_distance <= 10.0
                    start_points << z_mx - 1.0
                    start_points << z_mx - z_distance / 2.0
                    start_points << z_mx - z_distance + 1.0
                end
                start_points
            end

            def _cut_pocket_holes(model, group, rect, box_face, z_start_pts)
                z_start_pts.each do |z_pos|
                    start_pt = Geom::Point3d.new(rect.min_x, rect.min_y, z_pos)
                    pocket_screw__group = PocketScrew::PocketScrewGroup.create(start_pt, box_face, "neg")
                    next unless pocket_screw__group
                    cut_group = pocket_screw__group.position.group

                end
                group
            end

        end #class PocketScrewDrawer
    end # module Drawer
end # module AdamExtensions

