#
#  ctd_main.rb
#
#
#  Created by Adam Silver on 7/16/25.
#  copyright Adam Silver © 2025 all rights reserved

require 'sketchup.rb'
require 'extensions.rb'

module AdamExtensions

    module CubeToDrawer
        def conv(num, context="to_imperial")
            if context == "to_imperial"
                return num / 25.4
            else
                return num * 25.4
            end
        end

        def expand_rect(rect, x, y, z, context="metric")
            maxx = x==0 ? 0 : rect.max {|a,b| a.x<=>b.x}.x
            minx = x==0 ? 0 : rect.min {|a,b| a.x<=>b.x}.x
            maxy = y==0 ? 0 : rect.max {|a,b| a.y<=>b.y}.y
            miny = y==0 ? 0 : rect.min {|a,b| a.y<=>b.y}.y
            maxz = z==0 ? 0 : rect.max {|a,b| a.z<=>b.z}.z
            minz = z==0 ? 0 : rect.min {|a,b| a.z<=>b.z}.z
            x = context == "metric" ? x==0 ? 0 : conv(x) : x
            y = context == "metric" ? y==0 ? 0 : conv(y) : y
            z = context == "metric" ? z==0 ? 0 : conv(z) : z
            rect.each do |pt|
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
        end

        def move_rect(rect, x, y, z, context="metric")
            x = context == "metric" ? x==0 ? 0 : conv(x) : x
            y = context == "metric" ? y==0 ? 0 : conv(y) : y
            z = context == "metric" ? z==0 ? 0 : conv(z) : z
            rect.each {|pt| pt.x += x; pt.y += y; pt.z += z}
        end

        def copy_rect(old_rect, x=0, y=0, z=0, context="metric")
            new_rect = []
            old_rect.each {|e| new_rect << e.clone}
            move_rect(new_rect, x, y, z, context) if x!=0 && y!=0 && z!=0
            return new_rect
        end

        def create_bottom_panel(face_map, thickness, context="metric")
            # gate this function in case face_map is empty
            return unless face_map.has_key?("bottom")

            half_thickness = thickness/2
            base_rect = face_map["bottom"][:face_points]
            # copy and move up by 'thickness', then shrink
            # by half thickness
            top_rect = copy_rect(base_rect, 0, 0, thickness)
            expand_rect(top_rect, -half_thickness, -half_thickness, 0)
            mid_rect = copy_rect(base_rect, 0, 0, half_thickness)
            expand_rect(mid_rect, -thickness, -thickness, 0)
            # create the group...
            model = Sketchup.active_model
            model.start_operation("Create Drawer Bottom Group", true)
            group = model.entities.add_group
            upper_face = group.entities.add_face(top_rect)
            upper_face.pushpull(conv(-half_thickness))
            mid_face = group.entities.add_face(mid_rect)
            mid_face.pushpull(conv(half_thickness))
            model.commit_operation
        end

        def create_side_panel_right(face_map, thickness, context="metric")
            return unless face_map.has_key?("right")

            half_thickness = thickness/2
            base_rect = face_map["right"][:face_points]
            side_rect = copy_rect(base_rect)
            min_x = base_rect.map {|pt| pt.x}.min
            min_y = base_rect.map {|pt| pt.y}.min
            max_y = base_rect.map {|pt| pt.y}.max
            min_z = base_rect.map {|pt| pt.z}.min
            length = (max_y - min_y).abs
            cut_rect = [Geom::Point3d.new(min_x-conv(half_thickness), min_y, min_z+conv(half_thickness)),
                        Geom::Point3d.new(min_x-conv(half_thickness), min_y, min_z+conv(thickness)),
                        Geom::Point3d.new(min_x-conv(thickness), min_y, min_z+conv(thickness)),
                        Geom::Point3d.new(min_x-conv(thickness), min_y, min_z+conv(half_thickness))]
            model = Sketchup.active_model
            model.start_operation("Create Side Right Group", true)
            group = model.entities.add_group
            side_face = group.entities.add_face(side_rect)
            side_face.pushpull(conv(-thickness))
            cut_face = group.entities.add_face(cut_rect)
            cut_face.pushpull(-length)
            model.commit_operation
        end

        def create_side_panel_left(face_map, thickness, context="metric")
            return unless face_map.has_key?("left")

            half_thickness = thickness/2
            base_rect = face_map["left"][:face_points]
            side_rect = copy_rect(base_rect)
            min_x = base_rect.map {|pt| pt.x}.min
            min_y = base_rect.map {|pt| pt.y}.min
            max_y = base_rect.map {|pt| pt.y}.max
            min_z = base_rect.map {|pt| pt.z}.min
            length = (max_y - min_y).abs
            cut_rect = [Geom::Point3d.new(min_x+conv(half_thickness), min_y, min_z+conv(half_thickness)),
                        Geom::Point3d.new(min_x+conv(half_thickness), min_y, min_z+conv(thickness)),
                        Geom::Point3d.new(min_x+conv(thickness), min_y, min_z+conv(thickness)),
                        Geom::Point3d.new(min_x+conv(thickness), min_y, min_z+conv(half_thickness))]
            model = Sketchup.active_model
            model.start_operation("Create Side Left Group", true)
            group = model.entities.add_group
            side_face = group.entities.add_face(side_rect)
            side_face.pushpull(conv(-thickness))
            cut_face = group.entities.add_face(cut_rect)
            cut_face.pushpull(-length)
            model.commit_operation
        end

        def comp_face_map(face_map, s1, s2, pos, face)
            #load the map if that key spot is empty
            # first get the vertices points...
            face_end_points = face.vertices.map(&:position)
            if !face_map.key?(s1) and !face_map.key(s2)
                face_map[s1]= {"face_points": face_end_points, "pos": pos}
                face_map[s2]= {"face_points": face_end_points, "pos": pos}
                return
            end
            if pos < face_map[s1][:pos]
                face_map[s1][:face_points] = face_end_points
                face_map[s1][:pos] = pos
            elsif pos > face_map[s2][:pos]
                face_map[s2][:face_points] = face_end_points
                face_map[s2][:pos] = pos
            end
        end

        def load_face_map(face, face_map)
            x_pos = face.vertices.map {|vertex| vertex.position[0]}
            y_pos = face.vertices.map {|vertex| vertex.position[1]}
            z_pos = face.vertices.map {|vertex| vertex.position[2]}
            if x_pos.uniq.count <= 1 # it's a side
                comp_face_map(face_map, "left", "right", x_pos[0], face)
            elsif y_pos.uniq.count <= 1 # it's a front or back
                comp_face_map(face_map, "front", "back", y_pos[0], face)
            elsif z_pos.uniq.count <= 1 # it's a top or bottom
                comp_face_map(face_map, "bottom", "top", z_pos[0], face)
            end
        end

        #-------------------------------------------------------------------------------
        #  main Module code....
        #-------------------------------------------------------------------------------

#       unless file_loaded(__FILE__)
#           menu = UI.menu("Extensions").add_sub_menu("Cube to Drawer")
#           file_loaded(__FILE__)
#       end

        model = Sketchup.active_model
        sel = model.selection
        face_map = {}
        sel.each do |e|
            if e.is_a? Sketchup::Group
                group_entities = e.entities
                group_entities.each do |ge|
                    load_face_map(ge, face_map) if ge.is_a? Sketchup::Face
                end
                e.erase!
                break
            end
        end
        create_bottom_panel(face_map, 12)
        create_side_panel_right(face_map, 12)
        create_side_panel_left(face_map, 12)
        #face_map.each_pair{|p| puts p}

    end # module CubeToDrawer
end # module AdamExtensions
