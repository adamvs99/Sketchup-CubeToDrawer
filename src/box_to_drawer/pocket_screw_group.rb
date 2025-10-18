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
            @@offset_back = 0.5855
            @@offset_into = 0.2585
            def self.create(start_pt, drawer_face, direction = "pos")
                return false unless BoxShape::BoxMap::keysey.include?(drawer_face)

                case drawer_face
                when "front", "back"; axis = X_AXIS
                when "left", "right"; axis = Y_AXIS
                when "top", "bottom"; axis = Z_AXIS
                else
                    return nil
                end
                dir = direction.include?("pos") || direction.include?("plus") || direction=="+"  ?  1.0 : -1.0
                new(start_pt, drawer_face, axis, dir)
            end
            #@param [Geom::Point3d] start_pt
            #@param [Geom::Vector3d] axis
            def initialize(start_pt, drawer_face, axis, direction)
                @zero_point = [0, 0, 0]
                @start_pt = start_pt
                @cut_group = nil
                @direction = direction
                @drawer_face = drawer_face
                @axis = axis
                @lengths = 4.0
                make_circle_face = lambda do |_entities, _start_pt, _axis, _radius|
                    circle_edges = _entities.add_circle(_start_pt, _axis, _radius)
                    circle_curve = circle_edges.first.curve
                    faces_common_to_circle = circle_curve.faces
                    circle_face = faces_common_to_circle.find {|face| face.outer_loop.vertices == circle_curve.vertices }
                    circle_face
                end

                entities = Sketchup.active_model.active_entities
                @cut_group = entities.add_group
                # create a standard pocket screw hole on the X axis at 0,0,0
                # this will have the smaller diameter pointing to X+
                # both small and large diameters will be equal length so it can be
                # rotated easily with the start point int the center.
                large_circle_face = make_circle_face(entities, @zero_point, X_AXIS, 0.375)
                return nil if large_circle_face.nil?
                @cut_group.entities.add_face(large_circle_face)
                case axis
                when X_AXIS; large_circle_face.reverse! if large_circle_face.normal.x > 0
                when Y_AXIS; large_circle_face.reverse! if large_circle_face.normal.y > 0
                when Z_AXIS; large_circle_face.reverse! if large_circle_face.normal.z > 0
                end
                large_circle_face.pushpull(@lengths)

                small_circle_face = make_circle_face(entities,  @zero_point, X_AXIS, 0.166)
                return nil if small_circle_face.nil?
                @cut_group.entities.add_face(small_circle_face)
                case @axis
                when X_AXIS; large_circle_face.reverse! if large_circle_face.normal.x < 0
                when Y_AXIS; large_circle_face.reverse! if large_circle_face.normal.y < 0
                when Z_AXIS; large_circle_face.reverse! if large_circle_face.normal.z < 0
                end
                small_circle_face.pushpull(@lengths)
                @cut_group
            end # def initialize(start_pt, axis)

            def position
                # Note: offet_back = 0.5855, offet_out = 0.2585
                # move the group to the start point, note: the start point
                # is the center of the
                case @axis
                when X_AXIS
                    if @direction < 0.0
                        rotation = Geom::Transformation.rotation(@zero_point, Y_AXIS, 180.degrees)
                        @cut_group.transform!(rotation)
                    end
                    @start_pt.x -= @@offset_back*@direction
                    @start_pt.y -= @@offset_into*@direction
                when Y_AXIS
                    @cut_group.transform!(Geom::Transformation.rotation(@zero_point, Z_AXIS, 180.degrees))
                    @start_pt.y -= @@offset_back*@direction
                    @start_pt.x -= @@offset_into*@direction
                when Z_AXIS
                    @cut_group.transform!(Geom::Transformation.rotation(@zero_point, X_AXIS, 180.degrees))
                    @start_pt.z -= @@offset_back*@direction
                    @start_pt.y -= @@offset_into*@direction
                end
                # move the group to the start point
                @cut_group.transform!(Geom::Transformation.new(@start_pt))
                # rotate the group 15 degrees on the Z axis
                case @drawer_face
                when "front", "right", "bottom"; angle = -15.degrees
                when "back", "left", "top";  angle = 15.degrees
                end
                @cut_group.transform!(Geom::Transformation.rotation(@zero_point, @axis, 15.degrees))
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
