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

module AdamExtensions

    module CubeToDrawer


        # @param [CubeMap] facemap faces from selected cube
        # @param [Numeric] thickness of sides of drawer in mm
        # @param [String] context to convert thickness numeric
        def self.create_bottom_panel(face_map, thickness, units_type="metric")
            # gate this function in case face_map is empty
            return unless face_map.key?("bottom")
            half_thickness = thickness/2
            top_rect = face_map.to_rect_copy("bottom", 0, 0, thickness)
            top_rect.expand(-half_thickness, -half_thickness, 0, units_type)
            # top_rect._prnt("top_rect")
            mid_rect = face_map.to_rect_copy("bottom", 0, 0, half_thickness)
            mid_rect.expand(-thickness, -thickness, 0, units_type)
            # create the group...
            model = Sketchup.active_model
            model.start_operation("Create Drawer Bottom Group", true)
            in_half_thickness = Utils::in_unit(half_thickness, units_type)
            group = model.entities.add_group
            upper_face = group.entities.add_face(top_rect.points)
            upper_face.reverse! if upper_face.normal.z > 0
            upper_face.pushpull(in_half_thickness)
            mid_face = group.entities.add_face(mid_rect.points)
            mid_face.reverse! if mid_face.normal.z > 0
            mid_face.pushpull(in_half_thickness)
            model.commit_operation
        end

        # @param [Hash] facemap faces from selected cube
        # @param [Numeric] thickness of sides of drawer in mm
        # @param [String] context to convert thickness numeric
        def self.create_side_panel_right(face_map, thickness, units_type="metric")
            return unless face_map.key?("right")

            half_thickness = thickness/2
            in_thickness = Utils::in_unit(thickness, units_type)
            in_half_thickness = Utils::in_unit(half_thickness, units_type)
            side_rect = face_map.to_rect_copy("right")
            # create a face of the cut elongated cube item juts back of the 'front' of the initial cube
            model = Sketchup.active_model
            # create the 'side' piece
            model.start_operation("Create Side Right Group", true)
            side_group = model.entities.add_group
            side_face = side_group.entities.add_face(side_rect.points)
            side_face.reverse! if side_face.normal.x > 0
            side_face.pushpull(in_thickness)
            model.commit_operation
            # cut the bottom dado
            model.start_operation("Side Right Bottom dado", true)
            min_x = side_rect.min_x - in_thickness - in_half_thickness
            max_x = side_rect.min_x - in_half_thickness
            min_z = side_rect.min_z + in_half_thickness
            max_z = side_rect.min_z + in_thickness
            start_y = side_rect.min_y - in_half_thickness
            # points going clockwise on the X, Z plane...
            cut_rect = GeoUtil::Rect.new([Geom::Point3d.new(max_x, start_y, min_z),
                                          Geom::Point3d.new(min_x, start_y, min_z),
                                          Geom::Point3d.new(max_x, start_y, max_z),
                                          Geom::Point3d.new(min_x, start_y, max_z)])
            cut_group = model.entities.add_group
            cut_face = cut_group.entities.add_face(cut_rect.points)
            cut_face.reverse! if cut_face.normal.y < 0
            cut_face.pushpull(side_rect.depth+in_thickness)
            cut_group.subtract(side_group)
            model.commit_operation
        end
        # @param [Hash] facemap faces from selected cube
        # @param [Numeric] thickness of sides of drawer in mm
        # @param [String] context to convert thickness numeric
        def self.create_side_panel_left(face_map, thickness, context="metric")
            return unless face_map.key?("left")

            half_thickness = thickness/2
            base_rect = face_map["left"][:face_points]
            side_rect = face_map.(base_rect)
            min_x = base_rect.map {|pt| pt.x}.min
            min_y = base_rect.map {|pt| pt.y}.min
            max_y = base_rect.map {|pt| pt.y}.max
            min_z = base_rect.map {|pt| pt.z}.min
            length = (max_y - min_y).abs
            cut_rect = GeoUtil::Rect([Geom::Point3d.new(min_x+Utils::in_unit(half_thickness), min_y, min_z+Utils::in_unit(half_thickness)),
                        Geom::Point3d.new(min_x+Utils::in_unit(half_thickness), min_y, min_z+Utils::in_unit(thickness)),
                        Geom::Point3d.new(min_x+Utils::in_unit(thickness), min_y, min_z+Utils::in_unit(thickness)),
                        Geom::Point3d.new(min_x+Utils::in_unit(thickness), min_y, min_z+Utils::in_unit(half_thickness))])
            model = Sketchup.active_model
            model.start_operation("Create Side Left Group", true)
            group = model.entities.add_group
            side_face = group.entities.add_face(side_rect.points)
            side_face.pushpull(Utils::in_unit(-thickness))
            cut_face = group.entities.add_face(cut_rect.points)
            cut_face.pushpull(-length)
            model.commit_operation
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
            self.create_side_panel_right(cube_map, 12)
            #create_side_panel_left(cube_map, 12)
        end # def ctd_main

        unless file_loaded(__FILE__)
            menu = UI.menu("Extensions").add_item("Cube to Drawer") { self.ctd_main }
            file_loaded(__FILE__)
        end

    end # module CubeToDrawer
end # module AdamExtensions
