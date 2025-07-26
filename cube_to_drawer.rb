#
#  cube_toDrawer.rb
#
#
#  Created by Adam Silver on 7/16/25.
#  copyright Adam Silver © 2025 all rights reserved
require 'sketchup.rb'
require 'extensions.rb'

module HelloCube

    unless file_loaded?(__FILE__)
        ex = SketchupExtension.new('Cube To Drawer', 'cube_to_drawer/ctd_main')
        ex.description = 'SketchUp create drawer pieces from a selected cube.'
        ex.version = '1.0.0'
        ex.copyright = 'Adam Silver © 2025'
        ex.creator = 'Adam Silver'
        Sketchup.register_extension(ex, true)
        file_loaded(__FILE__)
    end

end # module HelloCube


