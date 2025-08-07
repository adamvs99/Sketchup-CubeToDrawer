#
#  cubic_shape.rb
#
#
#  Created by Adam Silver on 08/06/25.
#  copyright Adam Silver © 2025 all rights reserved

require 'sketchup.rb'
require 'extensions.rb'
require_relative 'rectangle'

module AdamExtensions

    module CubicShape
        #----------------------------------------------------------------------------------------------------------------------
        # CubeMap - encapsulates data on a 3d 'cube' into a Hash "top", "bottom", "left", "right, "front", "back"
        #----------------------------------------------------------------------------------------------------------------------
        class CubeMap
            def initialize(group, action="")
                @_cube_map = Hash.new
                return unless group.is_a? Sketchup::Group
                group.entities.each do |e|
                    next unless e.is_a? Sketchup::Face
                    face_points = e.vertices.map(&:position)
                    x_pos = e.vertices.map {|vertex| vertex.position[0]}
                    y_pos = e.vertices.map {|vertex| vertex.position[1]}
                    z_pos = e.vertices.map {|vertex| vertex.position[2]}
                    if x_pos.uniq.count <= 1 # it's a side
                        _sort_faces("left", "right", face_points, x_pos[0]) unless _loading("left", "right", face_points, x_pos[0])
                    elsif y_pos.uniq.count <= 1 # it's a front or back
                        _sort_faces("front", "back", face_points, y_pos[0]) unless _loading("front", "back", face_points, y_pos[0])
                    elsif z_pos.uniq.count <= 1 # it's a top or bottom
                        _sort_faces("bottom", "top", face_points, z_pos[0]) unless _loading("bottom", "top", face_points, z_pos[0])
                    end
                end
                _prnt
                group.erase! if action.include? "erase"
            end # def initialize

            def _prnt
                @_cube_map.each do |face, data|
                    puts face.ljust(8)   +   (data[:face_points][0]).to_s.ljust(22)
                    puts "".ljust(8) +   (data[:face_points][1]).to_s.ljust(22)
                    puts "".ljust(8) +   (data[:face_points][2]).to_s.ljust(22)
                    puts "".ljust(8) +   (data[:face_points][3]).to_s.ljust(22)
                end
            end
            def _loading(key_1, key_2, face_points, plane)
                if @_cube_map.key?(key_1) && @_cube_map.key?(key_2)
                    return false
                else
                    @_cube_map[key_1] = {"face_points": face_points, "plane": plane}
                    @_cube_map[key_2] = {"face_points": face_points, "plane": plane}
                end
                return true
            end #_loading

            def _sort_faces(key_1, key_2, face_points, plane)
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
                @_cube_map[which_face][:face_points]
            end # face_points

            def to_rect_copy(which_face, x=0, y=0, z=0, units_type="metric")
                rect = GeoUtil::Rect.new(face_points(which_face))
                return rect if rect.empty?
                rect.copy(x, y, z, units_type)
            end
        end # class CubeMap
    end # module LoadTest
end # module AdamExtensions

