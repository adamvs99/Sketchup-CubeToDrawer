#
#  units.rb
#
#
#  Created by Adam Silver on 08/28/25.
#  copyright Adam Silver © 2025 all rights reserved
require 'sketchup'

module AdamExtensions

    module ErrHandler
        class << self
            attr_accessor :_instance
        end

        self._instance = nil

        def self.instance
            self._instance = LanguageHandler.new('box_to_drawers.strings') if self._instance.nil?
            self._instance
        end

    end # module ErrHander

end # module AdamExtensions
