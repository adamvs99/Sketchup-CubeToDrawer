#
#  drawer.rb
#
#
#  Created by Adam Silver on 8/28/25.
#  copyright Adam Silver © 2025 all rights reserved

require 'sketchup.rb'
require 'json'
require_relative 'box_shape'
require_relative 'rectangle'
require_relative 'units'
require_relative 'utils'

module AdamExtensions
    module Drawer
        class Drawer

            @@drawers = []
            @@errors = nil

            #@param [group] the group to check
            #@param [group] the group to check
            def self.is_drawer_group?(group)
                return false unless group.is_a?(Sketchup::Group)
                sheet_thickness = group.get_attribute(Drawer.drawer_data_tag, "su-obj<sheet_thickness>")
                sheet_thickness&.positive?
            end

            def self.selection_to_drawers(action="", data=nil)
                selection = Sketchup.active_model.selection
                return false if selection&.empty?
                test_only = action.include?("test")
                groups = []
                created_box_groups = []
                selection.each do |s|
                    group, group_action, created_box_group = BoxShape::BoxMap.is_valid_selection?(s)
                    next unless group || created_box_group
                    Drawer.new(created_box_group.nil? ? group : created_box_group) unless test_only
                    groups << group if group && group_action.include?("erase")
                    created_box_group&.then {|v| created_box_groups << v}
                end
                has_groups = groups.size + created_box_groups.size > 0
                groups.each {|g| selection.remove(g); g.erase!} unless test_only
                created_box_groups.each {|g| g.erase!}
                Drawer.update(data)
                has_groups
            end

            def self.drawer_data_tag
                "avs_drawer_data"
            end

            def self.is_valid_drawer_data?(data)
                return false unless data.is_a?(Hash)
                keys = [:sheet_thickness, :dado_thickness, :dado_depth, :hidden_dado]
                return false unless keys.all? {|k| data.key?(k)}
                return false if data.values.include?(nil)
                @@errors = Utils::get_json_data("errors.json") if @@errors.nil?
                units_limits = @@errors["dimension_limits"][Units::units_type]
                units_notation = units_limits["json<units_notation>"]
                # test sheet thickness
                #limit_str = units_limits["json<sheet_thickness_min>"]
                #limit = Units::in_unit(Float(limit_str))
                #if data[:sheet_thickness] < limit
                #     err_string = @@errors[Units::local]["exceed_min_sheet"] + limit_str + units_notation
                #    UI.messagebox(err_string)
                #    return false
                #end
                #limit_str = units_limits["json<sheet_thickness_max>"]
                #limit = Units::in_unit(Float(limit_str))
                #if data[:sheet_thickness] > limit
                #    err_string = @@errors[Units::local]["exceed_max_sheet"] + limit_str + units_notation
                #    UI.messagebox(err_string)
                #    return false
                #end
                # test dado thickness vs sheet thickness
                if data[:dado_thickness] > data[:sheet_thickness]
                    err_string = @@errors[Units::local]["dado_greaterthan_sheet"]
                    UI.messagebox(err_string)
                    return false
                end
                limit_str = units_limits["json<dado_thickness_min>"]
                limit = Units::in_unit(Float(limit_str))
                if data[:dado_thickness] < limit
                    err_string = @@errors[Units::local]["exceed_min_dado"] + limit_str + units_notation
                    UI.messagebox(err_string)
                    return false
                end
                # test limits of dado depth & thickness
                limit = Float(data[:sheet_thickness] * 0.2)
                limit_str = (Units::in_to_current_units_type(data[:sheet_thickness] * 0.2)).round(2).to_s
                proceed = " " + @@errors[Units::local]["yes_no_proceed"]
                if data[:dado_thickness] < limit
                    err_string = @@errors[Units::local]["exceed_recommended_dado_width"] + limit_str + units_notation + proceed
                    return UI.messagebox(err_string, MB_YESNO) == IDYES
                end
                limit = Float(data[:sheet_thickness] * 0.8)
                limit_str = (Units::in_to_current_units_type(data[:sheet_thickness] * 0.8)).round(2).to_s
                if data[:dado_depth] > data[:sheet_thickness] * 0.8
                    err_string = @@errors[Units::local]["exceed_recommended_dado_depth"] + limit_str + units_notation + proceed
                    return UI.messagebox(err_string, MB_YESNO) == IDYES
                end
                true
            end

            def self.update(data)
                return if data.nil?
                @@drawers.each {|drawer| drawer._update(data) }
                @@drawers.clear
            end

            def initialize(box_group)
                @@errors = Utils::get_json_data("error.json") if @@errors.nil?
                @face_map = nil
                @current_groups = []
                @bounding_group = nil
                return unless box_group.is_a? Sketchup::Group
                @face_map = BoxShape::BoxMap.new(box_group)
                @@drawers << self if valid?
            end

            def valid?
                @face_map&.valid?
            end

            def _update(data)
                return unless valid?
                _clear_groups
                _create_bottom_panel(data)
                _create_left_right_panels(data)
                _create_front_back_panels(data)
                _create_bounding_group(data)
            end

            private

            def _create_bottom_panel(data)
                # gate this function if object not valid
                return unless valid?
                sheet_thickness, dado_thickness, dado_depth, hidden_dado = [data[:sheet_thickness],
                                                                            data[:dado_thickness],
                                                                            data[:dado_depth],
                                                                            data["hidden_dado"]]
                model = Sketchup.active_model
                bottom_rect = @face_map.to_rect_copy("bottom", 0, 0, sheet_thickness)
                bottom_upper_shrink = dado_depth-sheet_thickness
                bottom_rect.expand(bottom_upper_shrink, bottom_upper_shrink, 0)

                model.start_operation("Create Drawer Bottom Group", true)
                bottom_group = model.entities.add_group
                bottom_face = bottom_group.entities.add_face(bottom_rect.points)
                bottom_face.reverse! if bottom_face.normal.z > 0
                bottom_face.pushpull(sheet_thickness)
                model.commit_operation

                # cut left right rabbets ...
                origin = Geom::Point3d.new(bottom_rect.max_x - dado_depth,
                                           bottom_rect.min_y - dado_depth,
                                           bottom_rect.min_z - dado_thickness - sheet_thickness)
                cut_rect = GeoUtil::WDHRect.new(origin, dado_depth * 2, 0, sheet_thickness)
                model.start_operation("Bottom Right Rabbet", true)
                bottom_group = Utils.cut_channel(model, bottom_group, cut_rect, bottom_rect.depth+sheet_thickness, "y", "lt")
                model.commit_operation

                cut_rect.move(-bottom_rect.width, 0, 0)
                model.start_operation("Bottom Left Rabbet", true)
                bottom_group = Utils.cut_channel(model, bottom_group, cut_rect, bottom_rect.depth+sheet_thickness, "y", "lt")
                model.commit_operation

                # cut fron and back rabbets..
                cut_rect.flip("yz")
                cut_rect.move(dado_depth * 2, 0, 0)
                model.start_operation("Bottom Front Rabbet", true)
                bottom_group = Utils.cut_channel(model, bottom_group, cut_rect, bottom_rect.width+sheet_thickness, "x", "lt")
                model.commit_operation

                cut_rect.move(0, bottom_rect.depth, 0)
                model.start_operation("Bottom Rear Rabbet", true)
                @current_groups << Utils.cut_channel(model, bottom_group, cut_rect, bottom_rect.width+sheet_thickness, "x", "lt")
                model.commit_operation
            end #_create_bottom_panel

            def _create_left_right_panels(data)
                # gate this function if object not valid
                return unless valid?
                sheet_thickness, dado_thickness, dado_depth, hidden_dado = [data[:sheet_thickness],
                                                                            data[:dado_thickness],
                                                                            data[:dado_depth],
                                                                            data["hidden_dado"]]

                side_rect = @face_map.to_rect_copy("right")

                # create a face of the cut elongated box item just back of the 'front' of the initial box
                model = Sketchup.active_model
                # create the 'side' piece
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

                # cut the dado for the front piece
                cut_rect.move(0, sheet_thickness, side_rect.height)
                cut_rect.flip("xy")
                cut_length = side_rect.height+sheet_thickness
                model.start_operation("Side Right Rear Dado", true)
                right_side_group = Utils.cut_channel(model, right_side_group, cut_rect, cut_length)
                model.commit_operation

                # cut the dado for the front piece
                cut_rect.move(0, side_rect.depth - sheet_thickness * 2 + dado_thickness, 0)
                model.start_operation("Side Right Front Dado", true)
                right_side_group = Utils.cut_channel(model, right_side_group, cut_rect, cut_length)
                @current_groups << right_side_group
                model.commit_operation

                # create a copy .. move to left side .. rotate 180 degrees
                front_rect = @face_map.to_rect_copy("front")
                @current_groups << Utils.copy_move_rotate_group(right_side_group, -front_rect.width + sheet_thickness, 0, 0, Z_AXIS, 180)
            end # def create_side_panels

            def _create_front_back_panels(data)
                # gate this function if object not valid
                return unless valid?
                sheet_thickness, dado_thickness, dado_depth, hidden_dado = [data[:sheet_thickness],
                                                                            data[:dado_thickness],
                                                                            data[:dado_depth],
                                                                            data["hidden_dado"]]
                model = Sketchup.active_model
                base_rect = @face_map.to_rect_copy("front")

                model.start_operation("Create Front Panel", true)
                front_rect = base_rect.copy()
                front_rect.expand(-sheet_thickness + dado_depth, 0, 0)
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

                origin = Geom::Point3d.new(front_rect.max_x - dado_depth,
                                           front_rect.min_y - dado_thickness,
                                           front_rect.max_z + dado_thickness)
                cut_rect = GeoUtil::WDHRect.new(origin, dado_depth * 2, sheet_thickness, 0)
                cut_length = base_rect.height + sheet_thickness
                model.start_operation("Slice Right Rabbet", true)
                front_group = Utils.cut_channel(model, front_group, cut_rect, cut_length)
                model.commit_operation  # Create Front Panel

                cut_rect.move(-front_rect.width, 0, 0)
                model.start_operation("Slice Left Rabbet", true)
                front_group = Utils.cut_channel(model, front_group, cut_rect, base_rect.height + sheet_thickness)
                @current_groups << front_group
                model.commit_operation  # Create Front Panel

                side_rect = @face_map.to_rect_copy("left")
                @current_groups << Utils.copy_move_rotate_group(front_group, 0, side_rect.depth - sheet_thickness, 0, Z_AXIS, 180)
                model.commit_operation  # Slice Bottom Dado
            end # def create_side_front_back_panels

            def _create_bounding_group(data)
                # gate this function if object not valid
                return unless valid?
                sheet_thickness, dado_thickness, dado_depth, hidden_dado = [data[:sheet_thickness],
                                                                            data[:dado_thickness],
                                                                            data[:dado_depth],
                                                                            data["hidden_dado"]]
                group_data = {"su-obj<sheet_thickness>": sheet_thickness,
                              "su-obj<dado_thickness>":  dado_thickness,
                              "su-obj<dado_depth>":      dado_depth,
                              "su-obj<hidden_dado>":     hidden_dado }
                model = Sketchup.active_model
                bounding_group = model.entities.add_group
                @current_groups.each do |g|
                    component = bounding_group.entities.add_instance(g.definition, g.transformation)
                    Utils::tag_entity(component, Drawer.drawer_data_tag, group_data)
                    g.erase!
                end
                @current_groups.clear
                group_data["bounding_group"] = "drawer bounding group"
                Utils::tag_entity(bounding_group, Drawer.drawer_data_tag, group_data)
                @bounding_group = bounding_group
            end

            def _clear_groups
                @bounding_group&.erase! unless @bounding_group&.deleted?
                @bounding_group = nil
                @current_groups.each {|e| e.erase! if e&.respond_to?(:erase!)}
                @current_groups.clear
            end

        end # class Drawer
    end # module Drawer
end # module AdamExtensions