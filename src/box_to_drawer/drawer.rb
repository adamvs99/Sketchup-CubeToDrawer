#
#  drawer.rb
#
#
#  Created by Adam Silver on 8/28/25.
#  copyright Adam Silver © 2025 all rights reserved

require 'sketchup.rb'
require_relative 'box_shape'
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
            @@drawers = []

            def self.initialize_units
                # this gets called when a drawer is created
                # gate this if already there are already drawers
                # created
                return unless @@drawers.empty?
                case Units::units_type
                when 'imperial'
                    @@sheet_thickness = 0.75
                    @@dado_thickness = 0.25
                    @@dado_depth = 0.25
                when "metric"
                    @@sheet_thickness = Units.in_unit(18)
                    @@dado_thickness = Units.in_unit(6)
                    @@dado_depth =  Units.in_unit(6)
                when "cm_metric"
                    @@sheet_thickness =  Units.in_unit(1.8)
                    @@dado_thickness =  Units.in_unit(0.6)
                    @@dado_depth =  Units.in_unit(0.6)
                else
                    err = true
                end #case Units::unit_type
            end

            #@param [group] the group to check
            def self.is_drawer_group?(group)
                return false unless group.is_a?(Sketchup::Group)
                sheet_thickness = group.get_attribute("drawer_data", "sheet_thickness")
                sheet_thickness && sheet_thickness > 0.0
            end

            def self.hidden_dado?
                @@hidden_dado
            end
            def self.sheet_thickness
                @@sheet_thickness
            end
            def self.dado_thickness
                @@dado_thickness
            end
            def self.dado_depth
                @@dado_depth
            end

            def self.has_group?(group)
                @@drawers.each do |drawer|
                    return true if drawer.current_groups.include?(group)
                end
                false
            end
            def self.update
                @@drawers.each do |drawer|
                    next unless drawer.valid?
                    drawer.clear_groups
                    drawer.create_bottom_panel
                    drawer.create_left_right_panels
                    drawer.create_front_back_panels
                    drawer.create_bounding_group
                end
            end

            def self.selection_to_drawers(selection, action="")
                return if selection&.empty?
                groups = []
                selection.each do |s|
                    next unless BoxShape::BoxMap.is_aligned_box?(s)
                    Drawer.new(s)
                    groups << s
                end
                if action.include? "erase"
                    selection.clear
                    groups.each {|g| g.erase!}
                end
            end

            def initialize(box_group)
                @face_map = nil
                @current_groups = []
                @bounding_group = nil
                return unless box_group.is_a?(Sketchup::Group)
                @face_map = BoxShape::BoxMap.new(box_group)
                @@drawers << self if valid?
            end

            def valid?
                @face_map&.valid? && @@sheet_thickness > 0.0
            end
            def clear_groups
                @bounding_group&.erase! unless @bounding_group&.deleted?
                @bounding_group = nil
                @current_groups.each {|e| e.erase! if e&.respond_to?(:erase!)}
                @current_groups.clear
            end

            def current_groups
                @current_groups
            end

            def bounding_group
                @bounding_group
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

                # create a face of the cut elongated box item just back of the 'front' of the initial box
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

            def create_front_back_panels
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

            def create_bounding_group
                # gate this function if object not valid
                return unless valid?
                group_data = {"sheet_thickness":  @@sheet_thickness,
                              "dado_thickness": @@dado_thickness,
                              "dado_depth":     @@dado_depth,
                              "hidden_dado":    @@hidden_dado }
                model = Sketchup.active_model
                bounding_group = model.entities.add_group
                @current_groups.each do |g|
                    component = bounding_group.entities.add_instance(g.definition, g.transformation)
                    Utils::tag_entity(component, "drawer_data", group_data)
                    g.erase!
                end
                @current_groups.clear
                group_data["bounding_group"] = "drawer bounding group"
                Utils::tag_entity(bounding_group, "drawer_data", group_data)
                @bounding_group = bounding_group
            end

            # @param [hide_dados] boolean to hide or not to hide the dados
            # called from settings panel - triggers an update
            def self.update_hidden_dado(hide_dado)
                @@hidden_dado = hide_dado
                self.update
            end
            # called from settting panel - triggers an update
            def self.update_sheet_dado_values(new_sheet_thickness, new_dado_thickness, new_dado_depth)
                return if new_sheet_thickness==@@sheet_thickness && new_dado_thickness==@@dado_thickness && new_dado_depth==@@dado_depth
                @@sheet_thickness = new_sheet_thickness
                @@dado_thickness = new_dado_thickness
                @@dado_depth = new_dado_depth
                self.update
            end

        end # class Drawer
    end # module Drawer
end # module AdamExtensions