#
#  test_main.rb
#  entrypoint for unit testing
#
#  Created by Adam Silver on 7/16/25.
#  copyright Adam Silver © 2025 all rights reserved

require_relative '../src/box_to_drawer/rectangle.rb'
require_relative 'sketchup.rb'

module AdamExtensions

    def self.main
        test_rect = GeoUtil::WDHRect.new(Geom::Point3d.new(5,5,1), 5, 5, 0)
        test_rect_orig = test_rect.copy
        test_rect._prnt("orig rectangle")
        test_rect.flip("xz")
        test_rect._prnt("flip to xy->xz")
        test_rect.flip("xy")
        test_rect._prnt("flip to xz->xy")
        puts "tect_rect is xy->xz->xy: #{test_rect==test_rect_orig ? "yes" : "no!"}"
        puts " "

        test_rect.flip("yz")
        test_rect._prnt("flip to xz->yz")
        test_rect.flip("xy")
        test_rect._prnt("flip to yz->xy")
        puts "tect_rect is xy->yz->xy: #{test_rect==test_rect_orig ? "yes" : "no!"}"
        puts " "

        test_rect = GeoUtil::WDHRect.new(Geom::Point3d.new(5,5,1), 5, 0, 5)
        test_rect_orig = test_rect.copy
        test_rect._prnt("orig rectangle")
        test_rect.flip("xy")
        test_rect._prnt("flip to xz->xy")
        test_rect.flip("xz")
        test_rect._prnt("flip to xy->xz")
        puts "tect_rect is xz->xy->xz: #{test_rect==test_rect_orig ? "yes" : "no!"}"
        puts " "

        test_rect.flip("yz")
        test_rect._prnt("flip to xz->yz")
        test_rect.flip("xz")
        test_rect._prnt("flip to yz->xz")
        puts "tect_rect is xz->yz->xz: #{test_rect==test_rect_orig ? "yes" : "no!"}"
        puts " "


        test_rect = GeoUtil::WDHRect.new(Geom::Point3d.new(5,5,1), 0, 5, 5)
        test_rect_orig = test_rect.copy
        test_rect._prnt("orig rectangle")
        test_rect.flip("xy")
        test_rect._prnt("flip to yz->xy")
        test_rect.flip("yz")
        test_rect._prnt("flip to xy->yz")
        puts "tect_rect is yz->xy->yz: #{test_rect==test_rect_orig ? "yes" : "no!"}"
        puts " "

        test_rect.flip("xz")
        test_rect._prnt("flip to yz->xz")
        test_rect.flip("yz")
        test_rect._prnt("flip to xz->yz")
        puts "tect_rect is yz->xz->yz: #{test_rect==test_rect_orig ? "yes" : "no!"}"
        puts " "

    end

    self.main
end # module AdamExtensions
