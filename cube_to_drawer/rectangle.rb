#
#  rectangle.rb
#
#
#  Created by Adam Silver on 08/06/25.
#  copyright Adam Silver © 2025 all rights reserved

require 'sketchup.rb'
require_relative 'utils'

module AdamExtensions

    module GeoUtil
        #----------------------------------------------------------------------------------------------------------------------
        # Rect - encapsultes operations on a 'rectangle'
        #----------------------------------------------------------------------------------------------------------------------
        class Rect
            def initialize(corners)
                # Note: units are imperial
                if corners.empty?
                    @points = corners
                else
                    @points = [Geom::Point3d.new(corners[0]),
                               Geom::Point3d.new(corners[1]),
                               Geom::Point3d.new(corners[2]),
                               Geom::Point3d.new(corners[3])]
                end
            end

            def _prnt(title)
                puts "#{title} plane: #{orientation}   width: #{width} depth: #{depth} height: #{height}"
                @points.each_with_index do |pt, index|
                    #z = sprintf("%.9f", pt.z)
                    puts " ".ljust(10) + "[x: #{pt.x}, y: #{pt.y}, z: #{pt.z}]".ljust(40)
                end
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
                Geom::Point3d.new([min_x+width/2, min_y+depth/2,min_z+height/2])
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
                height==0 ? "xy" : width==0 ? :"yz" : "xz"
            end

            def _xz_to_xy
                new_z = min_z
                z_max = max_z
                h = height
                y_max = max_y
                @points.each do |pt|
                    pt.y += h if pt.z == z_max
                    pt.z = new_z
                end
            end

            def flip(new_orientation)
                return self if new_orientation==orientation
                orig_orientation = orientation
                if orig_orientation=="xy"
                    if new_orientation=="xz"
                        #TODO
                    elsif new_orientation=="yz"
                        #TODO
                    end
                elsif orig_orientation=="xz"
                    if new_orientation=="xy"
                        _xz_to_xy
                    elsif new_orientation=="yz"
                        #TODO
                    end
                else # orig_orientation=="yz"
                    if new_orientation=="xy"
                        #TODO
                    elsif new_orientation=="xz"
                        #TODO
                    end
                end
                self
            end

            def move(x=0, y=0, z=0, units_type="metric")
                return if x==0 && y==0 && z==0
                x = Utils::in_unit(x, units_type)
                y = Utils::in_unit(y, units_type)
                z = Utils::in_unit(z, units_type)
                @points.each {|pt| pt.x += x; pt.y += y; pt.z += z}
                self
            end

            def copy(x=0, y=0, z=0, units_type="metric")
                new_rect = Rect.new([])
                @points.each {|pt| new_rect << Geom::Point3d.new([pt.x, pt.y, pt.z])}
                new_rect.move(x, y, z, units_type)
                new_rect
            end

            def expand(x=0, y=0, z=0, units_type="metric")
                return self if x==0 && y==0 && z==0
                return self if @points.empty?
                minx = min_x; maxx = max_x
                miny = min_y; maxy = max_y
                minz = min_z; maxz = max_z
                x = Utils::in_unit(x, units_type)
                y = Utils::in_unit(y, units_type)
                z = Utils::in_unit(z, units_type)
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

            def change_edge(edge, amount, units_type="metric")
                return unless amount!=0
                amount = Utils::in_unit(amount, units_type)
                if edge == "bottom"
                    return unless ["xz", "yz"].include? orientation
                    mz = min_z
                    @points.each {|pt| pt.z += amount if pt.z==mz}
                elsif edge == "top"
                    return unless ["xz", "yz"].include? orientation
                    mz = max_z
                    @points.each {|pt| pt.z += amount if pt.z==mz}
                elsif edge == "front"
                    return unless ["xy", "yz"].include? orientation
                    my = min_y
                    @points.each {|pt| pt.y += amount if pt.y==my}
                elsif edge == "back"
                    return unless ["xy", "yz"].include? orientation
                    my = max_y
                    @points.each {|pt| pt.y += amount if pt.y==my}
                elsif edge == "left"
                    return unless ["xy", "xz"].include? orientation
                    mx = min_x
                    @points.each {|pt| pt.x += amount if pt.x==mx}
                elsif edge == "right"
                    return unless ["xy", "xz"].include? orientation
                    mx = max_x
                    @points.each {|pt| pt.x += amount if pt.x==mx}
                end
            end
        end # class Rect

    end # module GeoUtil
end # module AdamExtensions


