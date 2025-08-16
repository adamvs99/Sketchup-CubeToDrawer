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
require_relative 'units_dialog'
require 'pp'

module AdamExtensions

    module CubeToDrawer

        class << self
            attr_accessor:_units_type
            attr_accessor:_cube_map
            attr_accessor:_sheet_thickness
            attr_accessor:_dado_thickness
            attr_accessor:_current_groups
        end

        self._units_type = "metric"
        self._cube_map = nil
        self._sheet_thickness = 18
        self._dado_thickness = 6
        self._current_groups = []

        def self.update_sheet_dado_values(new_sheet_value, new_dado_value)
            valid_values = false
            begin
                new_sheet_thickness = Float(new_sheet_value)
                new_dado_thickness = Float(new_dado_value)
                valid_values = true
            rescue
                # Ignored
            end
            return unless valid_values
            return if new_sheet_thickness==self._sheet_thickness && new_dado_thickness==self._dado_thickness
            self._sheet_thickness = new_sheet_thickness
            self._dado_thickness = new_dado_thickness
            self._current_groups.each {|g| g.erase! if g.respond_to?(:erase!)}
            self._current_groups.clear
            self.update
        end
        # @param [CubeMap] facemap faces from selected cube
        # @param [Numeric] self._sheet_thickness of sides of drawer in mm
        # @param [String] context to convert self._sheet_thickness numeric
        def self.create_bottom_panel(face_map)
            # gate this function in case face_map is empty
            return unless face_map&.valid?
            model = Sketchup.active_model
            in_thickness = Utils::in_unit(self._sheet_thickness, self._units_type)
            in_dado_thickness = Utils::in_unit(self._dado_thickness, self._units_type)
            bottom_rect = face_map.to_rect_copy("bottom", 0, 0, self._sheet_thickness, self._units_type)
            bottom_rect.expand(-self._dado_thickness, -self._dado_thickness, 0, self._units_type)

            model.start_operation("Create Drawer Bottom Group", true)
            bottom_group = model.entities.add_group
            bottom_face = bottom_group.entities.add_face(bottom_rect.points)
            bottom_face.reverse! if bottom_face.normal.z > 0
            bottom_face.pushpull(in_thickness)
            model.commit_operation

            # cut left right rabbets
            min_x = bottom_rect.max_x - in_dado_thickness
            max_x = bottom_rect.max_x + in_dado_thickness
            min_z = bottom_rect.min_z - in_thickness - in_dado_thickness
            max_z = bottom_rect.max_z - in_dado_thickness
            all_y = bottom_rect.min_y - in_dado_thickness
            # points going clockwise on the X, Z plane...
            cut_rect = GeoUtil::Rect.new([Geom::Point3d.new(min_x, all_y, min_z),
                                          Geom::Point3d.new(min_x, all_y, max_z),
                                          Geom::Point3d.new(max_x, all_y, max_z),
                                          Geom::Point3d.new(max_x, all_y, min_z)])
            model.start_operation("Bottom Right Rabbet", true)
            bottom_group = Utils::cut_channel(model, bottom_group, cut_rect, bottom_rect.depth+in_thickness, "y", "lt")
            model.commit_operation

            cut_rect.move(-bottom_rect.width, 0, 0, "imperial")
            model.start_operation("Bottom Left Rabbet", true)
            bottom_group = Utils::cut_channel(model, bottom_group, cut_rect, bottom_rect.depth+in_thickness, "y", "lt")
            model.commit_operation

            cut_rect.flip("yz")
            model.start_operation("Bottom Front Rabbet", true)
            bottom_group = Utils::cut_channel(model, bottom_group, cut_rect, bottom_rect.width+in_thickness, "x", "lt")
            model.commit_operation

            cut_rect.move(0, bottom_rect.depth, 0, "imperial")
            model.start_operation("Bottom Rear Rabbet", true)
            self._current_groups << Utils::cut_channel(model, bottom_group, cut_rect, bottom_rect.width+in_thickness, "x", "lt")
            model.commit_operation
        end #self.create_bottom_panel

        # @param [Hash] face_map faces from selected cube
        # @param [Numeric] self._sheet_thickness of sides of drawer in mm
        # @param [String] context to convert self._sheet_thickness numeric
        def self.create_left_right_panels(face_map)
            return unless face_map&.valid?

            in_thickness = Utils::in_unit(self._sheet_thickness, self._units_type)
            in_dado_thickness = Utils::in_unit(self._dado_thickness, self._units_type)
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
            min_x = side_rect.min_x - in_thickness - in_dado_thickness
            max_x = side_rect.min_x - in_thickness + in_dado_thickness
            min_z = side_rect.min_z + in_thickness - in_dado_thickness
            max_z = side_rect.min_z + in_thickness
            all_y = side_rect.min_y - in_dado_thickness
            # points going clockwise on the X, Z plane...
            cut_rect = GeoUtil::Rect.new([Geom::Point3d.new(max_x, all_y, min_z),
                                          Geom::Point3d.new(min_x, all_y, min_z),
                                          Geom::Point3d.new(min_x, all_y, max_z),
                                          Geom::Point3d.new(max_x, all_y, max_z)])
            # cut bottom dado
            model.start_operation("Side Right Bottom Dado", true)
            right_side_group = Utils::cut_channel(model, right_side_group, cut_rect, side_rect.depth+in_thickness, "y", "lt")
            model.commit_operation

            # cut the dado for the front piece
            cut_rect.move(0, self._sheet_thickness, Utils::mm_unit(side_rect.height), self._units_type)
            cut_rect.flip("xy")
            model.start_operation("Side Right Rear Dado", true)
            right_side_group = Utils::cut_channel(model, right_side_group, cut_rect, side_rect.height+in_thickness)
            model.commit_operation

            # cut the dado for the front piece
            cut_rect.move(0, Utils::mm_unit(side_rect.depth) - self._sheet_thickness * 2 + self._dado_thickness, 0, self._units_type)
            model.start_operation("Side Right Front Dado", true)
            right_side_group = Utils::cut_channel(model, right_side_group, cut_rect, side_rect.height+in_thickness)
            self._current_groups << right_side_group
            model.commit_operation

            # create a copy .. move to left side .. rotate 180 degrees
            front_rect = face_map.to_rect_copy("front")
            self._current_groups << Utils::copy_move_rotate_group(right_side_group, -front_rect.width + in_thickness, 0, 0, "imperial", Z_AXIS, 180)
        end # def self.create_side_panels

        # @param [Hash] face_map faces from selected cube
        # @param [Numeric] thickness of sides of drawer in mm
        # @param [String] context to convert thickness numeric
        def self.create_front_back_panels(face_map)
            return unless face_map&.valid?
            model = Sketchup.active_model
            in_thickness = Utils::in_unit(self._sheet_thickness, self._units_type)
            in_dado_thickness = Utils::in_unit(self._dado_thickness, self._units_type)
            base_rect = face_map.to_rect_copy("front")

            model.start_operation("Create Front Panel", true)
            front_rect = base_rect.copy()
            front_rect.expand(-self._sheet_thickness+self._dado_thickness, 0, 0, self._units_type)
            front_group = model.entities.add_group
            front_face = front_group.entities.add_face(front_rect.points)
            front_face.reverse! if front_face.normal.y < 0
            front_face.pushpull(in_thickness)
            model.commit_operation  # Create Front Panel

            model.start_operation("Slice Bottom Dado", true)
            # cut the bottom dado
            min_y = base_rect.min_y + in_thickness - in_dado_thickness
            max_y = min_y + in_dado_thickness * 2
            min_z = base_rect.min_z + in_thickness - in_dado_thickness
            max_z = base_rect.min_z + in_thickness
            all_x = base_rect.max_x

            #create the bottom groove...
            cut_rect = GeoUtil::Rect.new([Geom::Point3d.new(all_x, min_y, min_z),
                                          Geom::Point3d.new(all_x, min_y, max_z),
                                          Geom::Point3d.new(all_x, max_y, max_z),
                                          Geom::Point3d.new(all_x, max_y, min_z)])
            front_group = Utils::cut_channel(model, front_group, cut_rect, base_rect.width, "x")
            model.commit_operation  # Create Front Panel

            # create the left and right insets...
            min_y = base_rect.min_y - in_dado_thickness
            max_y = min_y + in_thickness
            min_x = base_rect.max_x - in_thickness
            max_x = min_x + in_thickness
            all_z = base_rect.max_z + in_dado_thickness
            cut_rect = GeoUtil::Rect.new([Geom::Point3d.new(min_x, min_y, all_z),
                                          Geom::Point3d.new(min_x, max_y, all_z),
                                          Geom::Point3d.new(max_x, max_y, all_z),
                                          Geom::Point3d.new(max_x, min_y, all_z)])
            model.start_operation("Slice Right Rabbet", true)
            front_group = Utils::cut_channel(model, front_group, cut_rect, base_rect.height + in_thickness)
            model.commit_operation  # Create Front Panel

            cut_rect.move(-base_rect.width + in_thickness, 0, 0, "imperial")
            model.start_operation("Slice Left Rabbet", true)
            front_group = Utils::cut_channel(model, front_group, cut_rect, base_rect.height + in_thickness)
            self._current_groups << front_group
            model.commit_operation  # Create Front Panel

            side_rect = face_map.to_rect_copy("left")
            self._current_groups << Utils::copy_move_rotate_group(front_group, 0, side_rect.depth - in_thickness, 0, "imperial", Z_AXIS, 180)
            model.commit_operation  # Slice Bottom Dado
        end # def self.create_side_front_back_panels

        def self.update
            return unless self._cube_map&.valid?
            self.create_bottom_panel(self._cube_map)
            self.create_left_right_panels(self._cube_map)
            self.create_front_back_panels(self._cube_map)
        end

        #-------------------------------------------------------------------------------
        #  main Module code....
        #-------------------------------------------------------------------------------
        def self.ctd_main
            sel = Sketchup.active_model.selection
            unless sel.length != 1
                self._cube_map = CubicShape::CubeMap.new(sel[0], "erase")
                sel.clear
            end
            UnitsDialog.show
            self.update
        end # def ctd_main

        unless file_loaded(__FILE__)
            menu = UI.menu("Extensions").add_item("Cube to Drawer") { self.ctd_main }
            file_loaded(__FILE__)
        end

    end # module CubeToDrawer
end # module AdamExtensions
