#
#  utils.rb
#
#
#  Created by Adam Silver on 08/07/25.
#  copyright Adam Silver © 2025 all rights reserved

require 'sketchup.rb'
require 'json'
require_relative 'rectangle'

module AdamExtensions

    module Utils

        # @param [String] file name in the resource directory
        # @return [File object] target entity
        def self.get_resource_file(file_name)
            base_dir = __dir__.sub("box_to_drawer", "")
            return File.join(base_dir, "/resources", file_name)
        end

        def self.get_json_data(file_name)
            json_file = File.read(self.get_resource_file(file_name))
            return JSON.parse(json_file)
        end

        def self.write_pretty_json_data(filename, data)
            opts = { indent: "  ", space: " ", object_nl: "\n", array_nl: "\n" }
            File.write(self.get_resource_file(filename), JSON.pretty_generate(json_data, opts) + "\n")
        end

        # @param [Object] target entity
        # @param [String] name of the attribute dictionary
        # @param [Hash] hash of key/value pairs to be added to the attribute dictionary
        # @return [Object] target entity
        def self.tag_entity(entity, dict_name, dict)
            return unless entity&.is_a? Sketchup::Entity
            attribute_dict = entity.attribute_dictionary(dict_name, true)
            return entity if dict.nil? || attribute_dict.nil?
            dict.each {|key, value| attribute_dict[key] = value }
            entity
        end
        # @param [Sketchup::Model] current sketchup model
        # @param [Sketchup::Group] group to be re-shaped by the 'cut'
        # @param [GeoUtil::Rect] rectangle to extrude as the cut shape
        # @param [Numeric] length of the extrusion
        # @param [String] plane of the face to extrude from
        # @param [String] direction from the extrusion plane
        def self.cut_channel(model, target_group, cut_rect, cut_length, plane = "z", direction = "gt")
            cut_group = model.entities.add_group
            cut_face = cut_group.entities.add_face(cut_rect.points)
            case plane
            when "z"
                reverse_cut = direction=="gt" ? cut_face.normal.z > 0 : cut_face.normal.z < 0
            when "x"
                reverse_cut = direction=="gt" ? cut_face.normal.x > 0 : cut_face.normal.x < 0
            when "y"
                reverse_cut = direction=="gt" ? cut_face.normal.y > 0 : cut_face.normal.y < 0
            else
                # raise
            end
            cut_face.reverse! if reverse_cut
            cut_face.pushpull(cut_length)
            cut_group.subtract(target_group)
        end

        # @param [Sketchup::Group] group to be copied, moved, rotated
        # @param [Numeric] 'x' direction of move'
        # @param [Numeric] 'y' direction of move'
        # @param [Numeric] 'z' direction of move'
        # @param [Sketchup::CONSTANT] axis to rotate on, e.g., 'Z_AXIS'
        # @param [Numeric] rotation amount in degrees
        def self.copy_move_rotate_group(source_group, x, y, z, axis, angle)
            new_group = source_group.copy
            model = Sketchup.active_model
            model.start_operation("Copy Move Rotate", true)
            unless x==0 && y==0 && z==0
                move_params = Geom::Transformation.new(Geom::Point3d.new(x, y, z))
                new_group.transform!(move_params)
            end
            self.rotate(new_group, axis, angle) unless axis==0
            model.commit_operation
            new_group
        end # def copy_move_rotate_group

        def self.rotate(group, axis, angle, rotate_center = nil)
            rotate_pt = rotate_center || group.bounds.center
            group.transform!(Geom::Transformation.rotation(rotate_pt, axis, angle.degrees))
        end


        def self.generate_fastener_z_start_pts(z_mx, z_distance)
            #TODO: improve this...
            start_points = []
            if z_distance <= 1.5
                start_points << z_mx - z_distance / 2.0
            elsif z_distance <= 4.0
                z_div = z_distance / 3.0
                start_points << z_mx - z_div
                start_points << z_mx - z_div * 2.0
            else
                z_div = z_distance / 4.0
                start_points << z_mx - z_div
                start_points << z_mx - z_div * 2.0
                start_points << z_mx - z_div * 3.0
            end
            start_points
        end

    end # Utils
end # AdamExtensions
