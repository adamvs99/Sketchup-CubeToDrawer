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
require_relative 'sel_observer'
require 'pp'

module AdamExtensions

    module CubeToDrawer

        class << self
            attr_accessor :_units_type, :_cube_map, :_sheet_thickness, :_dado_thickness, :_dado_depth, :_current_groups, :_hidden_dado
        end

        self._units_type = "metric"
        self._cube_map = nil
        self._sheet_thickness = 18/25.4
        self._dado_thickness = 6/25.4
        self._dado_depth = 6/25.4
        self._current_groups = []
        self._hidden_dado = true

        def self.set_units_type
            model = Sketchup.active_model
            units_options = model.options["UnitsOptions"]

            length_format_code = units_options["LengthFormat"]
            length_unit_code = units_options["LengthUnit"]
            err = false

            # You can then use these codes to determine the actual unit string
            # based on the SketchUp API documentation for LengthFormat and LengthUnit enums.
            # For example:
            case length_format_code
            when 0 # Decimal
                case length_unit_code
                when 0
                    self._units_type = "imperial"
                    self._sheet_thickness = 0.75
                    self._dado_thickness = 0.25
                    self._dado_depth = 0.25
                when 1
                    err = true
                when 2
                    self._units_type = "metric"
                    self._sheet_thickness = Utils.in_unit(18, self._units_type)
                    self._dado_thickness = Utils.in_unit(6, self._units_type)
                    self._dado_depth =  Utils.in_unit(6, self._units_type)
                when 3
                    self._units_type = "cm_metric"
                    self._sheet_thickness =  Utils.in_unit(1.8, self._units_type)
                    self._dado_thickness =  Utils.in_unit(0.6, self._units_type)
                    self._dado_depth =  Utils.in_unit(0.6, self._units_type)
                when 4
                    err = true
                end
            when 1 # Architectural
                err = true
            when 2 # Engineering
                err = true
            when 3 # Fractional
                self._units_type = "imperial"
                self._sheet_thickness = 0.75
                self._dado_thickness = 0.25
                self._dado_depth = 0.25
            else
                err = true
            end
        end

        def self.drawer_groups
            self._current_groups
        end
        # @param [hide_dados] boolean to hide or not to hide the dados
        # called from settings panel - triggers an update
        def self.update_hidden_dado(hide_dados)
            self._hidden_dado = hide_dados
            self.update
        end
        # called from settting panel - triggers an update
        def self.update_sheet_dado_values(new_sheet_thickness, new_dado_thickness, new_dado_depth)
            return if new_sheet_thickness==self._sheet_thickness && new_dado_thickness==self._dado_thickness && new_dado_depth==self._dado_depth
            self._sheet_thickness = new_sheet_thickness
            self._dado_thickness = new_dado_thickness
            self._dado_depth = new_dado_depth
            self.update
        end

        # @param [CubeMap] facemap faces from selected cube
        # @param [Numeric] self._sheet_thickness of sides of drawer in mm
        # @param [String] context to convert self._sheet_thickness numeric
        def self.create_bottom_panel(face_map)
            # gate this function in case face_map is empty
            return unless face_map&.valid?
            model = Sketchup.active_model
            bottom_rect = face_map.to_rect_copy("bottom", 0, 0, self._sheet_thickness)
            bottom_upper_shrink = self._dado_depth-self._sheet_thickness
            bottom_rect.expand(bottom_upper_shrink, bottom_upper_shrink, 0)

            model.start_operation("Create Drawer Bottom Group", true)
            bottom_group = model.entities.add_group
            bottom_face = bottom_group.entities.add_face(bottom_rect.points)
            bottom_face.reverse! if bottom_face.normal.z > 0
            bottom_face.pushpull(self._sheet_thickness)
            model.commit_operation

            # cut left right rabbets ...
            origin = Geom::Point3d.new(bottom_rect.max_x - self._dado_depth,
                                       bottom_rect.min_y - self._dado_depth,
                                       bottom_rect.min_z - self._dado_thickness - self._sheet_thickness)
            cut_rect = GeoUtil::WDHRect.new(origin, self._dado_depth * 2, 0, self._sheet_thickness)
            model.start_operation("Bottom Right Rabbet", true)
            bottom_group = Utils.cut_channel(model, bottom_group, cut_rect, bottom_rect.depth+self._sheet_thickness, "y", "lt")
            model.commit_operation

            cut_rect.move(-bottom_rect.width, 0, 0)
            model.start_operation("Bottom Left Rabbet", true)
            bottom_group = Utils.cut_channel(model, bottom_group, cut_rect, bottom_rect.depth+self._sheet_thickness, "y", "lt")
            model.commit_operation

            # cut fron and back rabbets..
            cut_rect.flip("yz")
            cut_rect.move(self._dado_depth * 2, 0, 0)
            model.start_operation("Bottom Front Rabbet", true)
            bottom_group = Utils.cut_channel(model, bottom_group, cut_rect, bottom_rect.width+self._sheet_thickness, "x", "lt")
            model.commit_operation

            cut_rect.move(0, bottom_rect.depth, 0)
            model.start_operation("Bottom Rear Rabbet", true)
            self._current_groups << Utils.cut_channel(model, bottom_group, cut_rect, bottom_rect.width+self._sheet_thickness, "x", "lt")
            model.commit_operation
        end #self.create_bottom_panel

        # @param [Hash] face_map faces from selected cube
        # @param [Numeric] self._sheet_thickness of sides of drawer in mm
        # @param [String] context to convert self._sheet_thickness numeric
        def self.create_left_right_panels(face_map)
            return unless face_map&.valid?

            side_rect = face_map.to_rect_copy("right")
            # create a face of the cut elongated cube item juts back of the 'front' of the initial cube
            model = Sketchup.active_model
            # create the 'side' piece
            model.start_operation("Create Side Right Group", true)
            right_side_group = model.entities.add_group
            side_face = right_side_group.entities.add_face(side_rect.points)
            side_face.reverse! if side_face.normal.x > 0
            side_face.pushpull(self._sheet_thickness)
            model.commit_operation

            # cut the bottom dado
            origin = Geom::Point3d.new(side_rect.min_x - self._sheet_thickness - self._dado_depth,
                                       side_rect.min_y - self._dado_thickness,
                                       side_rect.min_z + self._sheet_thickness - self._dado_thickness)
            cut_rect = GeoUtil::WDHRect.new(origin, self._dado_depth * 2, 0, self._dado_thickness)
            cut_length = side_rect.depth+self._sheet_thickness
            # cut bottom dado
            model.start_operation("Side Right Bottom Dado", true)
            right_side_group = Utils.cut_channel(model, right_side_group, cut_rect, cut_length, "y", "lt")
            model.commit_operation

            # cut the dado for the front piece
            cut_rect.move(0, self._sheet_thickness, side_rect.height)
            cut_rect.flip("xy")
            cut_length = side_rect.height+self._sheet_thickness
            model.start_operation("Side Right Rear Dado", true)
            right_side_group = Utils.cut_channel(model, right_side_group, cut_rect, cut_length)
            model.commit_operation

            # cut the dado for the front piece
            cut_rect.move(0, side_rect.depth - self._sheet_thickness * 2 + self._dado_thickness, 0)
            model.start_operation("Side Right Front Dado", true)
            right_side_group = Utils.cut_channel(model, right_side_group, cut_rect, cut_length)
            self._current_groups << right_side_group
            model.commit_operation

            # create a copy .. move to left side .. rotate 180 degrees
            front_rect = face_map.to_rect_copy("front")
            self._current_groups << Utils.copy_move_rotate_group(right_side_group, -front_rect.width + self._sheet_thickness, 0, 0, Z_AXIS, 180)
        end # def self.create_side_panels

        # @param [Hash] face_map faces from selected cube
        # @param [Numeric] thickness of sides of drawer in mm
        # @param [String] context to convert thickness numeric
        def self.create_front_back_panels(face_map)
            return unless face_map&.valid?
            model = Sketchup.active_model
            base_rect = face_map.to_rect_copy("front")

            model.start_operation("Create Front Panel", true)
            front_rect = base_rect.copy()
            front_rect.expand(-self._sheet_thickness + self._dado_depth, 0, 0)
            front_group = model.entities.add_group
            front_face = front_group.entities.add_face(front_rect.points)
            front_face.reverse! if front_face.normal.y < 0
            front_face.pushpull(self._sheet_thickness)
            model.commit_operation  # Create Front Panel

            model.start_operation("Slice Bottom Dado", true)
            # cut the bottom dado
            origin = Geom::Point3d.new(base_rect.max_x,
                                       base_rect.min_y + self._sheet_thickness - self._dado_depth,
                                       base_rect.min_z + self._sheet_thickness - self._dado_thickness)
            cut_rect = GeoUtil::WDHRect.new(origin, 0, self._dado_depth * 2, self._dado_thickness)
            cut_length = base_rect.width + self._sheet_thickness
            front_group = Utils.cut_channel(model, front_group, cut_rect, cut_length, "x")
            model.commit_operation  # Create Front Panel

            origin = Geom::Point3d.new(front_rect.max_x - self._dado_depth,
                                       front_rect.min_y - self._dado_thickness,
                                       front_rect.max_z + self._dado_thickness)
            cut_rect = GeoUtil::WDHRect.new(origin, self._dado_depth * 2, self._sheet_thickness, 0)
            cut_length = base_rect.height + self._sheet_thickness
            model.start_operation("Slice Right Rabbet", true)
            front_group = Utils.cut_channel(model, front_group, cut_rect, cut_length)
            model.commit_operation  # Create Front Panel

            cut_rect.move(-front_rect.width, 0, 0)
            model.start_operation("Slice Left Rabbet", true)
            front_group = Utils.cut_channel(model, front_group, cut_rect, base_rect.height + self._sheet_thickness)
            self._current_groups << front_group
            model.commit_operation  # Create Front Panel

            side_rect = face_map.to_rect_copy("left")
            self._current_groups << Utils.copy_move_rotate_group(front_group, 0, side_rect.depth - self._sheet_thickness, 0, Z_AXIS, 180)
            model.commit_operation  # Slice Bottom Dado
        end # def self.create_side_front_back_panels

        def self.update
            return unless self._cube_map&.valid?
            self._current_groups.each {|g| g.erase! if g.respond_to?(:erase!)}
            self._current_groups.clear
            self.create_bottom_panel(self._cube_map)
            self.create_left_right_panels(self._cube_map)
            self.create_front_back_panels(self._cube_map)
        end

        #-------------------------------------------------------------------------------
        #  main Module code....
        #-------------------------------------------------------------------------------
        def self.ctd_main
            self.set_units_type
            sel = Sketchup.active_model.selection
            return unless sel.length==1
            self._cube_map = CubicShape::CubeMap.new(sel[0], "erase")
            return unless self._cube_map&.valid?
            sel.clear
            UnitsDialog.show
            SelectObserver.install
            self.update
        end # def ctd_main

        unless file_loaded(__FILE__)
            menu = UI.menu("Extensions").add_item("Cube to Drawer") { self.ctd_main }
            file_loaded(__FILE__)
        end

    end # module CubeToDrawer
end # module AdamExtensions
