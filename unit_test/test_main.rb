#
#  test_main.rb
#  entrypoint for unit testing
#
#  Created by Adam Silver on 7/16/25.
#  copyright Adam Silver © 2025 all rights reserved

require_relative '../src/cube_to_drawer/rectangle.rb'
require_relative 'sketchup.rb'

module AdamExtensions

    def self.main
        test_rect = GeoUtil::WDHRect.new(Geom::Point3d.new(5,5,1), 5, 5, 0)
        test_rect._prnt("rectangle")
        test_rect.flip("xz")
        test_rect._prnt("flip to xy->xz")
        test_rect.flip("yz")
        test_rect._prnt("flip to xz->yz")
        test_rect.flip("xy")
        test_rect._prnt("flip to yz->xy")
        test_rect.flip("yz")
        test_rect._prnt("flip to xy->yz")
        test_rect.flip("xz")
        test_rect._prnt("flip to yz->xz")
    end

    self.main
end # module AdamExtensions
