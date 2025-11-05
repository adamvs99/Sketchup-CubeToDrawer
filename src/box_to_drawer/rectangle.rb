#
#  rectangle.rb
#
#
#  Created by Adam Silver on 08/06/25.
#  copyright Adam Silver © 2025 all rights reserved
require 'sketchup.rb'
require 'extensions.rb'
#require_relative '../../unit_test/sketchup.rb' # for unit test

module AdamExtensions

    module GeoUtil
        #----------------------------------------------------------------------------------------------------------------------
        # Rect - encapsulates operations on a 'rectangle'
        # Note: all units are in imperial (decimal inch)
        #----------------------------------------------------------------------------------------------------------------------
        class Rect
            # @param corners: Array of Geom::Point3d
            # @return Rect
            # @return empty Rect if no corners are given
            def initialize(corners)
                # Note: units are imperial
                corners = Array.new if corners.nil?
                if corners.empty? || corners.size != 4
                    @points = []
                else
                    @points = [Geom::Point3d.new(corners[0]),
                               Geom::Point3d.new(corners[1]),
                               Geom::Point3d.new(corners[2]),
                               Geom::Point3d.new(corners[3])]
                end
                sort_rect
            end

            # @param - none
            # sorts in a clockwise direction such that:
            # xy - starting point is near left
            # xz - starting point is bottom left
            # yz - starting point is near bottom
            def sort_rect
                return if @points.empty?
                plane = orientation
                case plane
                when "xy"
                    mn_x = min_x; mx_x = max_x; mn_y = min_y; mx_y = max_y
                    new_points =[[mn_x, mn_y], [mn_x, mx_y], [mx_x, mx_y], [mx_x, mn_y]]
                    @points.each_with_index {|pt, index| pt.x = new_points[index][0]; pt.y = new_points[index][1]}
                when "xz"
                    mn_x = min_x; mx_x = max_x; mn_z = min_z; mx_z = max_z
                    new_points =[[mn_x, mn_z], [mn_x, mx_z], [mx_x, mx_z], [mx_x, mn_z]]
                    @points.each_with_index {|pt, index| pt.x = new_points[index][0]; pt.z = new_points[index][1]}
                when "yz"
                    mn_y = min_y; mx_y = max_y; mn_z = min_z; mx_z = max_z
                    new_points =[[mn_y, mn_z], [mn_y, mx_z], [mx_y, mx_z], [mx_y, mn_z]]
                    @points.each_with_index {|pt, index| pt.y = new_points[index][0]; pt.z = new_points[index][1]}
                else
                    # type code here
                end
                self
            end #_sort

            # @param - title: string
            # pretty prints header line of title orientation width depth height
            # followed by the rectangle point
            def _prnt(title)
                puts "#{title} plane: #{orientation}   width: #{width} depth: #{depth} height: #{height}"
                @points.each_with_index do |pt, index|
                    #z = sprintf("%.9f", pt.z)
                    puts " ".ljust(10) + "[x: #{pt.x}, y: #{pt.y}, z: #{pt.z}]".ljust(40)
                end
            end

            def ==(other)
                @points[0] == other.points[0] &&
                @points[1] == other.points[1] &&
                @points[2] == other.points[2] &&
                @points[3] == other.points[3]
            end

            def points
                @points
            end

            def <<(pt)
                @points << pt
            end

            def min_x
                @points.map {|pt| pt.x}.min
            end

            def max_x
                @points.map {|pt| pt.x}.max
            end

            def min_y
                @points.map {|pt| pt.y}.min
            end

            def max_y
                @points.map {|pt| pt.y}.max
            end

            def min_z
                @points.map {|pt| pt.z}.min
            end

            def max_z
                @points.map {|pt| pt.z}.max
            end

            def empty?
                @points.empty?
            end

            def centerpoint
                Geom::Point3d.new([min_x + width/2, min_y + depth/2,min_z + height/2])
            end

            def zero_rect?
                return true if @points.empty?
                @points[0]==@points[1] && @points[0]==@points[2] && @points[0]==@points[3]
            end

            def width
                (max_x - min_x).abs
            end

            def depth
                (max_y - min_y).abs
            end

            def height
                (max_z - min_z).abs
            end

            def orientation
                height==0 ? "xy" : width==0 ? "yz" : "xz"
            end

            # @param new_orientation: string
            # will fip the rectangle from one x,y, or z aligned plane to another
            def flip(new_orientation)
                return unless new_orientation == "xy" || new_orientation == "yz" || new_orientation == "xz"
                return self if new_orientation==orientation
                orig_orientation = orientation
                case orig_orientation
                when "xy"
                    if new_orientation=="xz"
                        mn_z = min_z; mx_z = min_z + depth
                        y = min_y
                        new_z = [mn_z, mx_z, mx_z, mn_z]
                        @points.each_with_index {|pt, index| pt.z = new_z[index]; pt.y = y}
                    elsif new_orientation=="yz"
                        mn_z = min_z; mx_z = min_z + width
                        x = min_x
                        new_z = [mn_z, mx_z, mx_z, mn_z]
                        @points.each_with_index {|pt, index| pt.z = new_z[index]; pt.x = x}
                    end
                when "xz"
                    if new_orientation=="xy"
                        mn_y = min_y; mx_y = min_y + height
                        z = min_z
                        new_y = [mn_y, mx_y, mx_y, mn_y]
                        @points.each_with_index {|pt, index| pt.y = new_y[index]; pt.z = z}
                    elsif new_orientation=="yz"
                        mn_x = min_x
                        mn_y = min_y; mx_y = min_y + width
                        new_y = [mn_y, mn_y, mx_y, mx_y]
                        @points.each_with_index {|pt, index| pt.x = mn_x; pt.y = new_y[index]}
                    end
                when "yz"
                    if new_orientation=="xy"
                        mn_x = min_x; mx_x = min_x + height
                        z = min_z
                        new_x = [mn_x, mn_x, mx_x, mx_x]
                        @points.each_with_index {|pt, index| pt.x = new_x[index]; pt.z = z}
                    elsif new_orientation=="xz"
                        mn_x = min_x; mx_x = min_x + depth
                        y = min_y
                        new_x = [mn_x, mn_x, mx_x, mx_x]
                        @points.each_with_index {|pt, index| pt.x = new_x[index]; pt.y = y}
                    end
                else
                    # type code here
                end
                self
            end

            # @param x: Numeric
            # @param y: Numeric
            # @param z: Numeric
            # Moves the rectangle along one or more x, y, or z aligned planes
            def move(x=0, y=0, z=0)
                return if x==0 && y==0 && z==0
                @points.each {|pt| pt.x += x; pt.y += y; pt.z += z}
                self
            end
            # @param x: Numeric
            # @param y: Numeric
            # @param z: Numeric
            # produces a new deep copy and moves it
            def copy(x=0, y=0, z=0)
                new_rect = Rect.new(@points)
                new_rect.move(x, y, z)
                new_rect
            end

            # @param x: Numeric
            # @param y: Numeric
            # @param z: Numeric
            # expands x, y, and or z symmetrically  from the center
            def expand(x=0, y=0, z=0)
                return self if x==0 && y==0 && z==0
                return self if @points.empty?
                minx = min_x; maxx = max_x
                miny = min_y; maxy = max_y
                minz = min_z; maxz = max_z
                @points.each do |pt|
                    if pt.x==maxx
                        pt.x += x
                    elsif pt.x==minx
                        pt.x -= x
                    end
                    if pt.y==maxy
                        pt.y += y
                    elsif pt.y==miny
                        pt.y -= y
                    end
                    if pt.z==maxz
                        pt.z += z
                    elsif pt.z==minz
                        pt.z -= z
                    end
                end
                self
            end # def expand

            def symetrically_expand(amount)
                return self if amount==0
                case orientation
                when "xy"
                    expand(amount, amount, 0)
                when "xz"
                    expand(amount, 0, amount)
                when "yz"
                    expand(0, amount, amount)
                end
                self
            end

            # @param edge: String
            # @param amount: Numeric
            # moves an edge by amount
            def change_edge(edge, amount)
                return unless amount!=0
                case edge
                when "bottom"
                    return unless ["xz", "yz"].include? orientation
                    mz = min_z
                    @points.each {|pt| pt.z += amount if pt.z==mz}
                when "top"
                    return unless ["xz", "yz"].include? orientation
                    mz = max_z
                    @points.each {|pt| pt.z += amount if pt.z==mz}
                when "front"
                    return unless ["xy", "yz"].include? orientation
                    my = min_y
                    @points.each {|pt| pt.y += amount if pt.y==my}
                when "back"
                    return unless ["xy", "yz"].include? orientation
                    my = max_y
                    @points.each {|pt| pt.y += amount if pt.y==my}
                when "left"
                    return unless ["xy", "xz"].include? orientation
                    mx = min_x
                    @points.each {|pt| pt.x += amount if pt.x==mx}
                when "right"
                    return unless ["xy", "xz"].include? orientation
                    mx = max_x
                    @points.each {|pt| pt.x += amount if pt.x==mx}
                else
                    # type code here
                end
            end
        end # class Rect

        #----------------------------------------------------------------------------------------------------------------------
        # WHRect - Rect but constructed using origin, width, height, plane as inputs
        # Note: all units are in imperial (decimal inch)
        #----------------------------------------------------------------------------------------------------------------------
        class WDHRect < Rect
            # @param [Sketchup::Geom::Point3d] origin point of the rectangle
            #                                  this is the lower left point
            # @param [Numeric] 'x' length
            # @param [Numeric] 'y' length
            # @param [Numeric] 'z' length
            # return WDHRect
            def initialize(origin, width, depth, height)
                # Note: units are imperial
                if width < 0
                    origin.x += width
                    width = width.abs
                end
                if depth < 0
                    origin.y += depth
                    depth = depth.abs
                end
                if height < 0
                    origin.z += height
                    height = height.abs
                end
                if height==0 # "xy" plane
                    # origin is the near, left corner
                    pts = [Geom::Point3d.new(origin.x, origin.y, origin.z),
                           Geom::Point3d.new(origin.x, origin.y+depth, origin.z),
                           Geom::Point3d.new(origin.x+width, origin.y+depth, origin.z),
                           Geom::Point3d.new(origin.x+width, origin.y, origin.z)]
                elsif depth==0 # "xz" plane
                    # origin is the near, left corner
                    pts = [Geom::Point3d.new(origin.x, origin.y, origin.z),
                           Geom::Point3d.new(origin.x, origin.y, origin.z+height),
                           Geom::Point3d.new(origin.x+width, origin.y, origin.z+height),
                           Geom::Point3d.new(origin.x+width, origin.y, origin.z)]
                elsif width==0# "yz" plane
                    # origin is the near, left corner
                    pts = [Geom::Point3d.new(origin.x, origin.y, origin.z),
                           Geom::Point3d.new(origin.x, origin.y, origin.z+height),
                           Geom::Point3d.new(origin.x, origin.y+depth, origin.z+height),
                           Geom::Point3d.new(origin.x, origin.y+depth, origin.z)]
                else
                    pts = []
                end
                super(pts)
            end
        end # class WDHRect

        class GlobalRect < Rect

            #@param [Sketchup::Face] face
            #@param [Sketchup::Transformation] transformation
            #@return [GlobalRect]
            def initialize(face, transformation)
                return super(nil) unless face&.is_a? Sketchup::Face
                global_points = face.vertices.map {|vertex| vertex.position.transform(transformation)}
                super(global_points)
            end # def initialize

        end # class GlobalRect
    end # module GeoUtil
end # module AdamExtensions


