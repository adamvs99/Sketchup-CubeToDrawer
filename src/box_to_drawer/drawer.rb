#
#  drawer.rb
#
#
#  Created by Adam Silver on 8/28/25.
#  copyright Adam Silver © 2025 all rights reserved

require 'sketchup.rb'
require 'securerandom'
require_relative 'box_shape'
require_relative 'units'
require_relative 'utils'
require_relative 'err_handler'

module AdamExtensions
    module Drawer
        class Drawer

            @@drawers = []
            @@limits = nil
            @@drawer_type = "simple_drawer"

            def self.new_type_selection(type)
                @@drawer_type = type
            end
            def self.drawer_factory(box_group)
                return nil unless box_group.is_a?(Sketchup::Group)
                case @@drawer_type
                when "simple_drawer"
                    require_relative 'simple_drawer'
                    return SimpleDrawer.new(box_group)
                when "pocket_screw_drawer"
                    require_relative 'pocket_screw_drawer'
                    return PocketScrewDrawer.new(box_group)
                when "advanced_dado_drawer"
                    require_relative 'advanced_dado_drawer'
                    return AdvancedDadoDrawer.new(box_group)
                else
                    return nil
                end
            end

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
                    self.drawer_factory(created_box_group.nil? ? group : created_box_group) unless test_only
                    groups << group if group && group_action.include?("erase")
                    created_box_group&.then {|v| created_box_groups << v}
                end
                has_groups = groups.size + created_box_groups.size > 0
                groups.each {|g| selection.remove(g); g.erase!} unless test_only
                created_box_groups.each {|g| g.erase!}
                self.update(data)
                has_groups
            end

            def self.drawer_data_tag
                "avs_drawer_data"
            end

            def self.drawer_type
                @@drawer_type
            end

            def self.is_valid_drawer_data?(data)
                return false unless data.is_a?(Hash)
                keys = [:sheet_thickness, :dado_thickness, :dado_depth]
                return false unless keys.all? {|k| data.key?(k)}
                return false if data.values.include?(nil)
                @@limits = Utils::get_json_data("limits.json") if @@limits.nil?
                units_limits = @@limits["dimension_limits"][Units::units_type]
                units_notation = units_limits["json<units_notation>"]

                # test sheet thickness
                #limit_str = units_limits["json<sheet_thickness_min>"]
                #limit = Units::in_unit(Float(limit_str))
                #if data[:sheet_thickness] < limit
                #     err_string = @@limits[Units::local]["exceed_min_sheet"] + limit_str + units_notation
                #    UI.messagebox(err_string)
                #    return false
                #end
                #limit_str = units_limits["json<sheet_thickness_max>"]
                #limit = Units::in_unit(Float(limit_str))
                #if data[:sheet_thickness] > limit
                #    err_string = @@limits[Units::local]["exceed_max_sheet"] + limit_str + units_notation
                #    UI.messagebox(err_string)
                #    return false
                #end

                # test dado thickness vs sheet thickness
                if data[:dado_thickness] > data[:sheet_thickness]
                    err_string = ErrHandler::instance["dado_greaterthan_sheet"]
                    UI.messagebox(err_string)
                    return false
                end
                limit_str = units_limits["json<dado_thickness_min>"]
                limit = Units::in_unit(Float(limit_str))
                if data[:dado_thickness] < limit
                    err_string = ErrHander::instance["exceed_min_dado"] + limit_str + units_notation
                    UI.messagebox(err_string)
                    return false
                end
                # test limits of dado depth & thickness
                limit = Float(data[:sheet_thickness] * 0.2)
                limit_str = (Units::in_to_current_units_type(data[:sheet_thickness] * 0.2)).round(2).to_s
                if data[:dado_thickness] < limit
                    proceed = " " + ErrHandler::instance["yes_no_proceed"]
                    err_string = ErrHandler::instance["exceed_recommended_dado_width"] + limit_str + units_notation + proceed
                    return UI.messagebox(err_string, MB_YESNO) == IDYES
                end
                limit = Float(data[:sheet_thickness] * 0.8)
                limit_str = (Units::in_to_current_units_type(limit)).round(2).to_s
                if data[:dado_depth] > data[:sheet_thickness] * 0.8
                    err_string = ErrHandler::instance["exceed_recommended_dado_depth"] + limit_str + units_notation + proceed
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
                @@limits = Utils::get_json_data("error.json") if @@limits.nil?
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

            protected

            def _create_bottom_panel(data)
                raise NotImplementedError, "#{self.class} must implement #_create_bottom_panel"
            end #_create_bottom_panel

            def _create_left_right_panels(data)
                raise NotImplementedError, "#{self.class} must implement #_create_left_right_panels"
            end # def create_side_panels

            def _create_front_back_panels(data)
                raise NotImplementedError, "#{self.class} must implement #_create_front_back_panels"
            end # def create_side_front_back_panels

            private

            def _create_bounding_group(data)
                # gate this function if object not valid
                return unless valid?
                sheet_thickness, dado_thickness, dado_depth = [data[:sheet_thickness],
                                                               data[:dado_thickness],
                                                               data[:dado_depth]]
                group_data = {"su-obj<drawer_type>":     self.drawer_type,
                              "su-obj<sheet_thickness>": sheet_thickness,
                              "su-obj<dado_thickness>":  dado_thickness,
                              "su-obj<dado_depth>":      dado_depth,
                              "su-obj<origin>":          Geom::Point3d.new(@face_map.origin),
                              "su-obj<width>":           @face_map.width,
                              "su-obj<depth>":           @face_map.depth,
                              "su-obj<height>":          @face_map.height,
                              "su-obj<guid>":            SecureRandom.uuid}
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