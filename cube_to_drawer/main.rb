#
#  main.rb
#
#
#  Created by Adam Silver on 7/16/25.
#  copyright Adam Silver © 2025 all rights reserved

require 'sketchup.rb'
require 'extensions.rb'
require_relative 'cubic_shape'

module AdamExtensions

    module CubeToDrawer


        # @param [CubeMap] facemap faces from selected cube
        # @param [Numeric] thickness of sides of drawer in mm
        # @param [String] context to convert thickness numeric
        def create_bottom_panel(face_map, thickness, context="metric")
            # gate this function in case face_map is empty
            return unless face_map.has_key?("bottom")

            half_thickness = thickness/2
            top_rect = face_map.to_rect_copy("bottom", 0, 0, thickness)
            top_rect.expand(-half_thickness, -half_thickness)
            mid_rect = face_map.to_rect_copy("bottom", 0, 0, half_thickness)
            mid_rect.expand(-thickness, -thickness, 0)
            # create the group...
            model = Sketchup.active_model
            model.start_operation("Create Drawer Bottom Group", true)
            group = model.entities.add_group
            upper_face = group.entities.add_face(top_rect)
            upper_face.pushpull(conv(-half_thickness))
            mid_face = group.entities.add_face(mid_rect)
            mid_face.pushpull(conv(-half_thickness))
            model.commit_operation
        end

        # @param [Hash] facemap faces from selected cube
        # @param [Numeric] thickness of sides of drawer in mm
        # @param [String] context to convert thickness numeric
        def create_side_panel_right(face_map, thickness, context="metric")
            return unless face_map.has_key?("right")

            half_thickness = thickness/2

            side_rect = face_map.to_rect_copy("right")
            # create a face of the cut elongated cube item juts back of the 'front' of the initial cube
            start_y = side_rect.min_y - half_thickness
            cut_rect = Rect.new([Geom::Point3d.new(min_x-conv(half_thickness), start_y, min_z+conv(half_thickness)),
                                        Geom::Point3d.new(min_x-conv(half_thickness), start_y, min_z+conv(thickness)),
                                        Geom::Point3d.new(min_x-conv(thickness), start_y, min_z+conv(thickness)),
                                        Geom::Point3d.new(min_x-conv(thickness), start_y, min_z+conv(half_thickness))])
            model = Sketchup.active_model
            # create the 'side' piece
            model.start_operation("Create Side Right Group", true)
            side_group = model.entities.add_group
            side_face = group.entities.add_face(side_rect)
            side_face.pushpull(conv(-thickness))
            model.commit_operation
            # cut the bottom dado
            model.start_operation("Side Right Bottom dado", true)
            cut_group = model.entities.add_group
            cut_face = group.entities.add_face(cut_rect)
            cut_face.pushpull(-side_rect.depth-thickness)
            cut_group.subtract(side_group)
            model.commit_operation
            group_map = CubeMap.new(side_group)
            # cut the back dado
            top_rect = group_map.to_rect_copy("top")
        end
        # @param [Hash] facemap faces from selected cube
        # @param [Numeric] thickness of sides of drawer in mm
        # @param [String] context to convert thickness numeric
        def create_side_panel_left(face_map, thickness, context="metric")
            return unless face_map.has_key?("left")

            half_thickness = thickness/2
            base_rect = face_map["left"][:face_points]
            side_rect = face_map.(base_rect)
            min_x = base_rect.map {|pt| pt.x}.min
            min_y = base_rect.map {|pt| pt.y}.min
            max_y = base_rect.map {|pt| pt.y}.max
            min_z = base_rect.map {|pt| pt.z}.min
            length = (max_y - min_y).abs
            cut_rect = [Geom::Point3d.new(min_x+conv(half_thickness), min_y, min_z+conv(half_thickness)),
                        Geom::Point3d.new(min_x+conv(half_thickness), min_y, min_z+conv(thickness)),
                        Geom::Point3d.new(min_x+conv(thickness), min_y, min_z+conv(thickness)),
                        Geom::Point3d.new(min_x+conv(thickness), min_y, min_z+conv(half_thickness))]
            model = Sketchup.active_model
            model.start_operation("Create Side Left Group", true)
            group = model.entities.add_group
            side_face = group.entities.add_face(side_rect)
            side_face.pushpull(conv(-thickness))
            cut_face = group.entities.add_face(cut_rect)
            cut_face.pushpull(-length)
            model.commit_operation
        end

        #-------------------------------------------------------------------------------
        #  main Module code....
        #-------------------------------------------------------------------------------
        def self.ctd_main
            sel = Sketchup.active_model.selection
            face_map = nil
            unless sel.length != 1
                face_map = CubicShape::CubeMap.new(sel[0])
                sel.clear
            end
            create_bottom_panel(face_map, 12)
            #create_side_panel_right(face_map, 12)
            #create_side_panel_left(face_map, 12)
        end # def ctd_main

        unless file_loaded(__FILE__)
            menu = UI.menu("Extensions").add_sub_menu("Cube to Drawer")
            self.ctd_main
            file_loaded(__FILE__)
        end

    end # module CubeToDrawer
end # module AdamExtensions
