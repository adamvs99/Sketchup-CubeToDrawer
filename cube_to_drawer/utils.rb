#
#  utils.rb
#
#
#  Created by Adam Silver on 08/07/25.
#  copyright Adam Silver © 2025 all rights reserved

require 'sketchup.rb'

module AdamExtensions

    module Utils
        def self.in_unit(num, units_type = "metric")
            return num if num==0 || units_type != "metric"
            num / 25.4
        end
        def self.mm_unit(num, units_type = "imperial")
            return num if num==0 || units_type != "imperial"
            num * 25.4
        end

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
        def self.copy_move_rotate_group(source_group, x, y, z, units_type, axis, angle)
            new_group = source_group.copy
            model = Sketchup.active_model
            model.start_operation("Copy Move Rotate", true)
            x = self.in_unit(x, units_type)
            y = self.in_unit(y, units_type)
            z = self.in_unit(z, units_type)
            unless x==0 && y==0 && z==0
                move_params = Geom::Transformation.new(Geom::Point3d.new(x, y, z))
                new_group.transform!(move_params)
            end
            unless axis==0
                rotate_params = Geom::Transformation.rotation(new_group.bounds.center, axis, angle.degrees)
                new_group.transform!(rotate_params)
            end
            model.commit_operation
            new_group
        end # def copy_move_rotate_group
    end # Utils
end # AdamExtensions
