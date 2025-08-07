#
#  utils.rb
#
#
#  Created by Adam Silver on 08/07/25.
#  copyright Adam Silver © 2025 all rights reserved

module AdamExtensions

    module Utils
        def self.in_unit(num, units_type = "metric")
            return num if num==0 || units_type != "metric"
            num / 25.4
        end
        def self.mm_unit(num, units_type = "imperial")
            return num if num==0 || units_type != "imperial"
            num * 25.4
        end

    end # Utils
end # AdamExtensions
