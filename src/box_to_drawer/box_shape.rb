#
#  cubic_shape.rb
#
#
#  Created by Adam Silver on 08/06/25.
#  copyright Adam Silver © 2025 all rights reserved

require 'sketchup.rb'
require 'extensions.rb'
require_relative 'rectangle'
require 'pp'

module AdamExtensions

    module BoxShape
        #----------------------------------------------------------------------------------------------------------------------
        # BoxMap - encapsulates data on a 3d 'cube' into a Hash "top", "bottom", "left", "right, "front", "back"
        # Note: all units are in imperial (decimal inch)
        #----------------------------------------------------------------------------------------------------------------------
        class BoxMap
            def initialize(group)
                @_cube_map = nil
                return unless group.is_a? Sketchup::Group
                @_cube_map = Hash.new
                group.entities.each do |face|
                    next unless face.is_a? Sketchup::Face
                    face_points = GeoUtil::GlobalRect.new(face)
                    x_pos = face_points.points.map {|pt| pt.x}
                    y_pos = face_points.points.map {|pt| pt.y}
                    z_pos = face_points.points.map {|pt| pt.z}
                    if x_pos.uniq.count <= 1 # it's a side
                        _sort_faces("left", "right", face_points, x_pos[0]) unless _loading("left", "right", face_points, x_pos[0])
                    elsif y_pos.uniq.count <= 1 # it's a front or back
                        _sort_faces("front", "back", face_points, y_pos[0]) unless _loading("front", "back", face_points, y_pos[0])
                    elsif z_pos.uniq.count <= 1 # it's a top or bottom
                        _sort_faces("bottom", "top", face_points, z_pos[0]) unless _loading("bottom", "top", face_points, z_pos[0])
                    end
                end
            end # def initialize

            def self.is_aligned_cube?(cube_group)
                return false unless cube_group&.is_a? Sketchup::Group
                face_count = 0; x_plane = 0; y_plane = 0; z_plane = 0
                cube_group.entities.grep(Sketchup::Face).each do |f|
                    face_count += 1
                    x_plane += 1 if f.normal.parallel?(X_AXIS) && f.bounds.min.x.abs
                    y_plane += 1 if f.normal.parallel?(Y_AXIS) && f.bounds.min.y.abs
                    z_plane += 1 if f.normal.parallel?(Z_AXIS) && f.bounds.min.z.abs
                end
                return false unless face_count == 6
                return false unless x_plane == 2 && y_plane == 2 && z_plane == 2
                true
            end

            def valid?
                #@_cube_map.key?("bottom") && @_cube_map.key?("top") &&
                #@_cube_map.key?("left") && @_cube_map.key?("right") &&
                #@_cube_map.key?("front") && @_cube_map.key?("back")
                @_cube_map.size == 6
            end
            def _prnt
                @_cube_map.each do |face, data|
                    puts face.ljust(8)   +   (data[:face_points].points[0]).to_s.ljust(22)
                    puts "".ljust(8) +   (data[:face_points].points[1]).to_s.ljust(22)
                    puts "".ljust(8) +   (data[:face_points].points[2]).to_s.ljust(22)
                    puts "".ljust(8) +   (data[:face_points].points[3]).to_s.ljust(22)
                end
            end
            def _loading(key_1, key_2, face_points, plane)
                # this loads the initial values into both keys, e.g., "top", "bottom",
                # and returns 'true' meaning it WAS loading
                return false if @_cube_map.key?(key_1) && @_cube_map.key?(key_2)
                @_cube_map[key_1] = {"face_points": face_points, "plane": plane}
                @_cube_map[key_2] = {"face_points": face_points, "plane": plane}
                true
            end #_loading

            def _sort_faces(key_1, key_2, face_points, plane)
                # both keys will be the same after loading so this
                # puts the 'opposite' key in the correct spot, by
                # which plane is indicated. E.g. if the "top" values
                # were loaded into both "top" and "bottom" keys the "bottom"
                # would replace the first of the key pair because it's 'plane',
                # or Z plane in this case is less than the "top" plane.
                if plane < @_cube_map[key_1][:plane]
                    @_cube_map[key_1][:face_points] = face_points
                    @_cube_map[key_1][:plane] = plane
                elsif plane > @_cube_map[key_2][:plane]
                    @_cube_map[key_2][:face_points] = face_points
                    @_cube_map[key_2][:plane] = plane
                end
            end #_sort_faces

            def key?(key)
                @_cube_map.key?(key)
            end

            def face_points(which_face)
                return [] unless @_cube_map.key?(which_face)
                @_cube_map[which_face][:face_points].points
            end # face_points

            def to_rect_copy(which_face, x=0, y=0, z=0)
                rect = @_cube_map[which_face][:face_points]
                return GeoUtil::Rect.new([]) if rect.empty?
                rect.copy(x, y, z)
            end
        end # class BoxMap
    end # module BoxShape
end # module AdamExtensions

