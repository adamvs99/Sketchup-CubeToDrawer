#
#  units.rb
#
#
#  Created by Adam Silver on 08/28/25.
#  copyright Adam Silver © 2025 all rights reserved

module AdamExtensions

    module Units
    class << self
        attr_reader :_mm_in, :_cm_in
        attr_accessor :_units_type
    end

    self._units_type = ""
    self._mm_in = 25.4
    self._cm_in = 2.54
    module Units
        def self.set_units_type
            model = Sketchup.active_model
            units_options = model.options["UnitsOptions"]

            length_format_code = units_options["LengthFormat"]
            length_unit_code = units_options["LengthUnit"]
            err = false
            # You can then use these codes to determine the actual unit string
            # based on the SketchUp API documentation for LengthFormat and LengthUnit enums.
            # For example:
            case length_format_code
            when 0 # Decimal
                case length_unit_code
                when 0
                    self._units_type = "imperial"
                when 1
                    err = true
                when 2
                    self._units_type = "metric"
                when 3
                    self._units_type = "cm_metric"
                when 4
                    err = true
                end
            when 1 # Architectural
                err = true
            when 2 # Engineering
                err = true
            when 3 # Fractional
                self._units_type = "imperial"
            else
                err = true
            end

        end

        def self.units_type
            self._units_type
        end
        # @param [Numeric] number to be converted
        # @param [String] units type of the number to be converted
        #                 if already in the target type nothing is
        #                 done
        def self.in_unit(num, units_type = "auto")
            units_type = self._units_type if units_type == "auto"
            return num if num==0 || units_type == "imperial"
            units_type == "metric" ? num / self._mm_in : num / self._cm_in
        end

        # @param [Numeric] number to be converted
        # @param [String] units type of the number to be converted
        #                 if already in the target type nothing is
        #                 done
        def self.mm_unit(num, units_type = "auto")
            units_type = self._units_type if units_type == "auto"
            return num if num==0 || units_type == "metric"
            num * self._mm_in
        end

        # @param [Numeric] number to be converted
        # @param [String] units type of the number to be converted
        #                 if already in the target type nothing is
        #                 done
        def self.cm_unit(num, units_type = "auto")
            units_type = self._units_type if units_type == "auto"
            return num if num==0 || units_type == "cm_metric"
            num * self._cm_in
        end

    end # module Units
end # module AdamExtensions
