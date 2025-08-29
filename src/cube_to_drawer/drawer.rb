#
#  drawer.rb
#
#
#  Created by Adam Silver on 8/28/25.
#  copyright Adam Silver © 2025 all rights reserved

require 'sketchup.rb'
require_relative 'cubic_shape.rb'
require_relative 'rectangle'
require_relative 'units'
require_relative 'utils'

module AdamExtensions
    module Drawer
        class Drawer

            @@sheet_thickness = 0.0
            @@dado_thickness = 0.0
            @@dado_depth = 0.0
            @@hidden_dado = false

            self.initialize_units(length_format_code, length_unit_code)
                # You can then use these codes to determine the actual unit string
                # based on the SketchUp API documentation for LengthFormat and LengthUnit enums.
                case length_format_code
                when 0 # Decimal
                    case length_unit_code
                    when 0
                        @@sheet_thickness = 0.75
                        @@dado_thickness = 0.25
                        @@dado_depth = 0.25
                    when 1
                        err = true
                    when 2
                        @@sheet_thickness = Units.in_unit(18)
                        @@dado_thickness = Units.in_unit(6)
                        @@dado_depth =  Units.in_unit(6)
                    when 3
                        @@sheet_thickness =  Units.in_unit(1.8)
                        @@dado_thickness =  Units.in_unit(0.6)
                        @@dado_depth =  Units.in_unit(0.6)
                    when 4
                        err = true
                    end
                when 1 # Architectural
                    err = true
                when 2 # Engineering
                    err = true
                when 3 # Fractional
                    @@sheet_thickness = 0.75
                    @@dado_thickness = 0.25
                    @@dado_depth = 0.25
                else
                    err = true
                end
            end

            def initialize(cubic_group)
                @face_map = nil
                @current_groups = []
                return unless cubic_group.is_a?(Sketchup::Group)
                @face_map = CubicShape::CubeMap.new(cubic_group, "erase")
                return unless self._cube_map&.valid?
                sel.clear
            end

            def valid?
                @face_map?.valid && @@sheet_thickness > 0
            end

            def create_bottom_panel
                # gate this function if object not valid
                return unless valid?
                model = Sketchup.active_model
                bottom_rect = @face_map.to_rect_copy("bottom", 0, 0, @@sheet_thickness)
                bottom_upper_shrink = @@dado_depth-@@sheet_thickness
                bottom_rect.expand(bottom_upper_shrink, bottom_upper_shrink, 0)

                model.start_operation("Create Drawer Bottom Group", true)
                bottom_group = model.entities.add_group
                bottom_face = bottom_group.entities.add_face(bottom_rect.points)
                bottom_face.reverse! if bottom_face.normal.z > 0
                bottom_face.pushpull(@@sheet_thickness)
                model.commit_operation

                # cut left right rabbets ...
                origin = Geom::Point3d.new(bottom_rect.max_x - @@dado_depth,
                                           bottom_rect.min_y - @@dado_depth,
                                           bottom_rect.min_z - @@dado_thickness - @@sheet_thickness)
                cut_rect = GeoUtil::WDHRect.new(origin, @@dado_depth * 2, 0, @@sheet_thickness)
                model.start_operation("Bottom Right Rabbet", true)
                bottom_group = Utils.cut_channel(model, bottom_group, cut_rect, bottom_rect.depth+@@sheet_thickness, "y", "lt")
                model.commit_operation

                cut_rect.move(-bottom_rect.width, 0, 0)
                model.start_operation("Bottom Left Rabbet", true)
                bottom_group = Utils.cut_channel(model, bottom_group, cut_rect, bottom_rect.depth+@@sheet_thickness, "y", "lt")
                model.commit_operation

                # cut fron and back rabbets..
                cut_rect.flip("yz")
                cut_rect.move(@@dado_depth * 2, 0, 0)
                model.start_operation("Bottom Front Rabbet", true)
                bottom_group = Utils.cut_channel(model, bottom_group, cut_rect, bottom_rect.width+@@sheet_thickness, "x", "lt")
                model.commit_operation

                cut_rect.move(0, bottom_rect.depth, 0)
                model.start_operation("Bottom Rear Rabbet", true)
                @current_groups << Utils.cut_channel(model, bottom_group, cut_rect, bottom_rect.width+@@sheet_thickness, "x", "lt")
                model.commit_operation
            end #create_bottom_panel

            def create_left_right_panels
                # gate this function if object not valid
                return unless valid?

                side_rect = @face_map.to_rect_copy("right")
                # create a face of the cut elongated cube item juts back of the 'front' of the initial cube
                model = Sketchup.active_model
                # create the 'side' piece
                model.start_operation("Create Side Right Group", true)
                right_side_group = model.entities.add_group
                side_face = right_side_group.entities.add_face(side_rect.points)
                side_face.reverse! if side_face.normal.x > 0
                side_face.pushpull(@@sheet_thickness)
                model.commit_operation

                # cut the bottom dado
                origin = Geom::Point3d.new(side_rect.min_x - @@sheet_thickness - @@dado_depth,
                                           side_rect.min_y - @@dado_thickness,
                                           side_rect.min_z + @@sheet_thickness - @@dado_thickness)
                cut_rect = GeoUtil::WDHRect.new(origin, @@dado_depth * 2, 0, @@dado_thickness)
                cut_length = side_rect.depth+@@sheet_thickness
                # cut bottom dado
                model.start_operation("Side Right Bottom Dado", true)
                right_side_group = Utils.cut_channel(model, right_side_group, cut_rect, cut_length, "y", "lt")
                model.commit_operation

                # cut the dado for the front piece
                cut_rect.move(0, @@sheet_thickness, side_rect.height)
                cut_rect.flip("xy")
                cut_length = side_rect.height+@@sheet_thickness
                model.start_operation("Side Right Rear Dado", true)
                right_side_group = Utils.cut_channel(model, right_side_group, cut_rect, cut_length)
                model.commit_operation

                # cut the dado for the front piece
                cut_rect.move(0, side_rect.depth - @@sheet_thickness * 2 + @@dado_thickness, 0)
                model.start_operation("Side Right Front Dado", true)
                right_side_group = Utils.cut_channel(model, right_side_group, cut_rect, cut_length)
                @current_groups << right_side_group
                model.commit_operation

                # create a copy .. move to left side .. rotate 180 degrees
                front_rect = @face_map.to_rect_copy("front")
                @current_groups << Utils.copy_move_rotate_group(right_side_group, -front_rect.width + @@sheet_thickness, 0, 0, Z_AXIS, 180)
            end # def self.create_side_panels

            def self.create_front_back_panels
                # gate this function if object not valid
                return unless valid?
                model = Sketchup.active_model
                base_rect = @face_map.to_rect_copy("front")

                model.start_operation("Create Front Panel", true)
                front_rect = base_rect.copy()
                front_rect.expand(-@@sheet_thickness + @@dado_depth, 0, 0)
                front_group = model.entities.add_group
                front_face = front_group.entities.add_face(front_rect.points)
                front_face.reverse! if front_face.normal.y < 0
                front_face.pushpull(@@sheet_thickness)
                model.commit_operation  # Create Front Panel

                model.start_operation("Slice Bottom Dado", true)
                # cut the bottom dado
                origin = Geom::Point3d.new(base_rect.max_x,
                                           base_rect.min_y + @@sheet_thickness - @@dado_depth,
                                           base_rect.min_z + @@sheet_thickness - @@dado_thickness)
                cut_rect = GeoUtil::WDHRect.new(origin, 0, @@dado_depth * 2, @@dado_thickness)
                cut_length = base_rect.width + @@sheet_thickness
                front_group = Utils.cut_channel(model, front_group, cut_rect, cut_length, "x")
                model.commit_operation  # Create Front Panel

                origin = Geom::Point3d.new(front_rect.max_x - @@dado_depth,
                                           front_rect.min_y - @@dado_thickness,
                                           front_rect.max_z + @@dado_thickness)
                cut_rect = GeoUtil::WDHRect.new(origin, @@dado_depth * 2, @@sheet_thickness, 0)
                cut_length = base_rect.height + @@sheet_thickness
                model.start_operation("Slice Right Rabbet", true)
                front_group = Utils.cut_channel(model, front_group, cut_rect, cut_length)
                model.commit_operation  # Create Front Panel

                cut_rect.move(-front_rect.width, 0, 0)
                model.start_operation("Slice Left Rabbet", true)
                front_group = Utils.cut_channel(model, front_group, cut_rect, base_rect.height + @@sheet_thickness)
                @current_groups << front_group
                model.commit_operation  # Create Front Panel

                side_rect = @face_map.to_rect_copy("left")
                @current_groups << Utils.copy_move_rotate_group(front_group, 0, side_rect.depth - @@sheet_thickness, 0, Z_AXIS, 180)
                model.commit_operation  # Slice Bottom Dado
            end # def self.create_side_front_back_panels

            # @param [hide_dados] boolean to hide or not to hide the dados
            # called from settings panel - triggers an update
            def update_hidden_dado(hide_dado)
                @@hidden_dado = hide_dado
                self.update
            end
            # called from settting panel - triggers an update
            def update_sheet_dado_values(new_sheet_thickness, new_dado_thickness, new_dado_depth)
                return if new_sheet_thickness==@@sheet_thickness && new_dado_thickness==@@dado_thickness && new_dado_depth==@@dado_depth
                @@sheet_thickness = new_sheet_thickness
                @@dado_thickness = new_dado_thickness
                @@dado_depth = new_dado_depth
                self.update
            end

            def update
                return unless valid?
                @current_groups.each {|g| g.erase! if g.respond_to?(:erase!)}
                @current_groups.clear
                create_bottom_panel
                create_left_right_panels
                create_front_back_panels
            end

        end # class Drawer

    end # module Drawer
end # module AdamExtensions