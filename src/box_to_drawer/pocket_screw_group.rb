#
#  pocket_screw_group.rb
#
#
#  Created by Adam Silver on 10/15/25.
#  copyright Adam Silver © 2025 all rights reserved

require 'sketchup.rb'

module AdamExtensions

    module PocketScrew
        #----------------------------------------------------------------------------------------------------------------------
        # PocketScrew - creates a pocket screw group top be used to subtract from
        #               a drawer side group.
        #----------------------------------------------------------------------------------------------------------------------
        class PocketScrewGroup
            private_class_method :new
            @@offset_back_lrg = 0.45629921
            @@offset_into_lrg = 0.12244094
            @@offset_back_sml = 0.26614173
            @@offset_into_sml = 0.18937008
            @@offset_threashold = 0.65000000
            def self.create(start_pt, drawer_face, sheet_thickness, direction = "pos")
                return false unless BoxShape::BoxMap::keyset.include?(drawer_face)

                case drawer_face
                when "front", "back"; axis = X_AXIS
                when "left", "right"; axis = Y_AXIS
                when "top", "bottom"; axis = Z_AXIS
                else
                    return nil
                end
                dir = direction.include?("pos") || direction.include?("plus") || direction=="+"  ?  1.0 : -1.0
                pocket_screw_group = new(start_pt, drawer_face, axis, sheet_thickness, dir)
                return pocket_screw_group unless pocket_screw_group
                pocket_screw_group
            end
            #@param [Geom::Point3d] start_pt
            #@param [Geom::Vector3d] axis
            def initialize(start_pt, drawer_face, axis, sheet_thickness, direction)
                @zero_point = Geom::Point3d.new
                @start_pt = start_pt
                @direction = direction
                @drawer_face = drawer_face
                @cut_group_guid = nil
                @axis = axis
                @lengths = 4.0
                @sheet_thickness = sheet_thickness
                @offset_back = @sheet_thickness > @@offset_threashold ? @@offset_back_lrg : @@offset_back_sml
                @offset_into = @sheet_thickness > @@offset_threashold ? @@offset_into_lrg : @@offset_into_sml
                cylinder = lambda { |_guid, _length, _radius, _dir|
                    _group = Sketchup.active_model.find_entity_by_id(_guid)
                    circle = _group.entities.add_circle(@zero_point, X_AXIS, _radius)
                    circle_vertices = circle.map(&:vertices).map(&:first)
                    face = _group.entities.add_face(circle_vertices)
                    face.reverse! if face.normal.x * _dir < 0
                    face.pushpull(_length)
                    _group = nil
                    face = nil
                }

                @cut_group_guid = Sketchup.active_model.active_entities.add_group.guid
                # this will have the smaller diameter pointing to X+
                # both small and large diameters will be equal length so it can be
                # rotated easily with the start point int the center.
                large_radius = @sheet_thickness > @@offset_threashold ? 0.1875 : 0.1485
                cylinder.call(@cut_group_guid, @lengths, large_radius, -1.0)
                cylinder.call(@cut_group_guid, @lengths, 0.083, 1.0)

            end # def initialize(start_pt, axis)

            def position
                # Note: offet_back = 0.5855, offet_out = 0.2585
                # move the group to the start point, note: the start point
                # is the center of the
                cut_group = self.group
                case @axis
                when X_AXIS
                    Utils.rotate(cut_group, Z_AXIS, 180) if @direction < 0.0
                    @start_pt.x -= @offset_back*@direction
                    @start_pt.y -= @offset_into*@direction
                when Y_AXIS
                    Utils.rotate(cut_group, Z_AXIS, @direction * 90)
                    @start_pt.y -= @offset_back*@direction
                    @start_pt.x -= @offset_into*@direction
                when Z_AXIS
                    Utils.rotate(cut_group, Y_AXIS, @direction * 90)
                    @start_pt.z -= @offset_back*@direction
                    @start_pt.y -= @offset_into*@direction
                end
                # move the group to the start point
                cut_group.transform!(Geom::Transformation.new(@start_pt))
                rotate_axis = @axis==X_AXIS || @axis==Y_AXIS ? Z_AXIS : X_AXIS
                # rotate the group 15 degrees on the Z axis
                case @drawer_face
                when "front", "right", "bottom"; angle = -15.0
                when "back", "left", "top";  angle = 15.0
                end
                Utils.rotate(cut_group, rotate_axis, angle)
                self
            end
            def group
                Sketchup.active_model.find_entity_by_id(@cut_group_guid)
            end
            def orientation
                @axis
            end
            def start_point
                @start_pt
            end

        end # class PocketScrewGroup
    end # module PocketScrew
end # module AdamExtensions
