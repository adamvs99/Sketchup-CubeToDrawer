#
#  main.rb
#
#
#  Created by Adam Silver on 7/16/25.
#  copyright Adam Silver © 2025 all rights reserved

require 'sketchup.rb'
require 'extensions.rb'
require_relative 'cubic_shape'
require_relative 'rectangle'
require_relative 'utils'
require 'pp'

module AdamExtensions

    module CubeToDrawer


        # @param [CubeMap] facemap faces from selected cube
        # @param [Numeric] thickness of sides of drawer in mm
        # @param [String] context to convert thickness numeric
        def self.create_bottom_panel(face_map, thickness, units_type="metric")
            # gate this function in case face_map is empty
            return unless face_map.key?("bottom")
            half_thickness = thickness/2
            in_half_thickness = Utils::in_unit(half_thickness, units_type)
            bottom_rect = face_map.to_rect_copy("bottom", 0, 0, 0, units_type)
            mid_rect = bottom_rect.copy(0, 0, half_thickness, units_type)
            bottom_rect.expand(-thickness, -thickness, 0, units_type)
            mid_rect.expand(-half_thickness, -half_thickness, 0, units_type)
            bottom_rect._prnt("bottom_rect")
            # create the group...
            model = Sketchup.active_model
            model.start_operation("Create Drawer Bottom Group", true)
            group = model.entities.add_group
            bottom_face = group.entities.add_face(bottom_rect.points)
            bottom_face.reverse! if bottom_face.normal.z < 0
            bottom_face.pushpull(in_half_thickness)
            mid_face = group.entities.add_face(mid_rect.points)
            mid_face.reverse! if mid_face.normal.z < 0
            mid_face.pushpull(in_half_thickness)
            model.commit_operation
        end

        # @param [Hash] facemap faces from selected cube
        # @param [Numeric] thickness of sides of drawer in mm
        # @param [String] context to convert thickness numeric
        def self.create_side_panels(face_map, thickness, units_type="metric")
            return unless face_map.key?("right")

            half_thickness = thickness/2
            in_thickness = Utils::in_unit(thickness, units_type)
            in_half_thickness = Utils::in_unit(half_thickness, units_type)
            side_rect = face_map.to_rect_copy("right")
            # create a face of the cut elongated cube item juts back of the 'front' of the initial cube
            model = Sketchup.active_model
            # create the 'side' piece
            model.start_operation("Create Side Right Group", true)
            right_side_group = model.entities.add_group
            side_face = right_side_group.entities.add_face(side_rect.points)
            side_face.reverse! if side_face.normal.x > 0
            side_face.pushpull(in_thickness)
            model.commit_operation

            # cut the bottom dado
            min_x = side_rect.min_x - in_thickness - in_half_thickness
            max_x = side_rect.min_x - in_half_thickness
            min_z = side_rect.min_z + in_half_thickness
            max_z = side_rect.min_z + in_thickness
            start_y = side_rect.min_y - in_half_thickness
            # points going clockwise on the X, Z plane...
            cut_rect = GeoUtil::Rect.new([Geom::Point3d.new(max_x, start_y, min_z),
                                          Geom::Point3d.new(min_x, start_y, min_z),
                                          Geom::Point3d.new(min_x, start_y, max_z),
                                          Geom::Point3d.new(max_x, start_y, max_z)])
            # cut bottom dado
            model.start_operation("Side Right Bottom Dado", true)
            cut_group = model.entities.add_group
            cut_face = cut_group.entities.add_face(cut_rect.points)
            cut_face.reverse! if cut_face.normal.y < 0
            cut_face.pushpull(side_rect.depth+in_thickness)
            right_side_group = cut_group.subtract(right_side_group)
            model.commit_operation

            # cut the dado for the back piece
            model.start_operation("Side Right Rear Dado", true)
            cut_rect.move(0, thickness, Utils::mm_unit(side_rect.height), units_type)
            cut_rect.flip("xy")
            cut_group = model.entities.add_group
            cut_face = cut_group.entities.add_face(cut_rect.points)
            cut_face.reverse! if cut_face.normal.z > 0
            cut_face.pushpull(side_rect.height+in_thickness)
            right_side_group = cut_group.subtract(right_side_group)
            model.commit_operation

            # cut the dado for the front piece
            model.start_operation("Side Right Front Dado", true)
            cut_rect.move(0, Utils::mm_unit(side_rect.depth) - thickness - half_thickness, 0, units_type)
            cut_group = model.entities.add_group
            cut_face = cut_group.entities.add_face(cut_rect.points)
            cut_face.reverse! if cut_face.normal.z > 0
            cut_face.pushpull(side_rect.height+in_thickness)
            right_side_group = cut_group.subtract(right_side_group)
            model.commit_operation

            # create a copy .. move to left side .. rotate 180 degrees
            front_rect = face_map.to_rect_copy("front")
            Utils::copy_move_rotate_group(right_side_group, -front_rect.width + in_thickness, 0, 0, "imperial", Z_AXIS, 180)
            #front_rect = face_map.to_rect_copy("front")
            #left_side_group = right_side_group.copy
            #move_params = Geom::Transformation.new(Geom::Point3d.new(-front_rect.width + in_thickness, 0, 0))
            #left_side_group.transform!(move_params)
            #model.commit_operation
            #model.start_operation("Side Left Rotate 180", true)
            #rotate_params = Geom::Transformation.rotation(left_side_group.bounds.center, Z_AXIS, 180.degrees)
            #left_side_group.transform!(rotate_params)
         end
        # @param [Hash] facemap faces from selected cube
        # @param [Numeric] thickness of sides of drawer in mm
        # @param [String] context to convert thickness numeric
        def self.create_side_front_back_panels(face_map, thickness, units_type="metric")
            return unless face_map.key?("front")
            model = Sketchup.active_model
            in_thickness = Utils::in_unit(thickness, units_type)
            half_thickness = thickness/2
            in_half_thickness = Utils::in_unit(half_thickness, units_type)
            base_rect = face_map.to_rect_copy("front")

            model.start_operation("Create Front Panel", true)
            front_rect = base_rect.copy(0, thickness, 0, units_type)
            front_rect.expand(-half_thickness, 0, 0, units_type)
            front_group = model.entities.add_group
            front_face = front_group.entities.add_face(front_rect.points)
            front_face.reverse! if front_face.normal.z < 0
            front_face.pushpull(in_half_thickness)
            front_rect.move(0, -half_thickness, 0, units_type)
            front_rect.expand(-half_thickness, 0, 0, units_type)
            front_face = front_group.entities.add_face(front_rect.points)
            front_face.reverse! if front_face.normal.z < 0
            front_face.pushpull(in_half_thickness)
            model.commit_operation  # Create Front Panel

            model.start_operation("Slice Bottom Dado", true)
            # cut the bottom dado
            min_y = base_rect.min_y + in_half_thickness
            max_y = min_y + in_thickness
            min_z = base_rect.min_z + in_half_thickness
            max_z = base_rect.min_z + in_thickness
            start_x = base_rect.max_x
            # points going clockwise on the X, Z plane...
            cut_rect = GeoUtil::Rect.new([Geom::Point3d.new(start_x, min_y, min_z),
                                          Geom::Point3d.new(start_x, min_y, max_z),
                                          Geom::Point3d.new(start_x, max_y, max_z),
                                          Geom::Point3d.new(start_x, max_y, min_z)])
            cut_group = model.entities.add_group
            cut_face = cut_group.entities.add_face(cut_rect.points)
            cut_face.reverse! if cut_face.normal.z < 0
            cut_face.pushpull(base_rect.width)
            front_group = cut_group.subtract(front_group)
            side_rect = face_map.to_rect_copy("left")
            Utils::copy_move_rotate_group(front_group, 0, side_rect.depth - in_thickness, 0, "imperial", Z_AXIS, 180)
            model.commit_operation  # Slice Bottom Dado

            #model.start_operation("Copy Move Front Panel", true)
            #model.commit_operation  # Slice Bottom Dado
        end

        #-------------------------------------------------------------------------------
        #  main Module code....
        #-------------------------------------------------------------------------------
        def self.ctd_main
            sel = Sketchup.active_model.selection
            cube_map = nil
            unless sel.length != 1
                cube_map = CubicShape::CubeMap.new(sel[0], "erase")
                sel.clear
            end
            self.create_bottom_panel(cube_map, 12)
            self.create_side_panels(cube_map, 12)
            self.create_side_front_back_panels(cube_map, 12)
        end # def ctd_main

        unless file_loaded(__FILE__)
            menu = UI.menu("Extensions").add_item("Cube to Drawer") { self.ctd_main }
            file_loaded(__FILE__)
        end

    end # module CubeToDrawer
end # module AdamExtensions
