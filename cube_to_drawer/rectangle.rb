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
                    # put the origin, ie, the min x,y,z point in
                    # position 0
                    mx = min_x
                    my = min_y
                    mz = min_z
                    @points.each_with_index do |pt, index|
                        if mx==pt.x && my==pt.y && mz==pt.z
                            @points[0],@points[index] = @points[index],@points[0]
                            break
                        end
                    end
                end
            end

            def _prnt(title)
                title += " " + orientation
                @points.each_with_index do |pt, index|
                    title="" if index > 0
                    puts title.ljust(20) + "[x: #{pt.x}, y: #{pt.y}, z: #{pt.z}]".ljust(40)
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

            def flip(new_orientation)
                return self if new_orientation==orientation
                orig_orientation = orientation
                @points.each do |pt|
                    if orig_orientation=="xy"
                        if new_orientation=="xz"
                            pt.y,pt.z = pt.z,pt.y
                        elsif new_orientation=="yz"
                            pt.x,pt.z = pt.z,pt.x
                        end
                    elsif orig_orientation=="xz"
                        if new_orientation=="xy"
                            pt.y,pt.z = pt.z,pt.y
                        elsif new_orientation=="yz"
                            pt.x,pt.y = pt.y,pt.x
                        end
                    else # orig_orientation=="yz"
                        if new_orientation=="xy"
                            pt.x,pt.z = pt.z,pt.x
                        elsif new_orientation=="xz"
                            pt.x,pt.y = pt.y,pt.x
                        end
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
        end # class Rect

    end # module GeoUtil
end # module AdamExtensions


