#
#  dimensions_dialog.rb
#
#
#  Created by Adam Silver on 08/14/25.
#  copyright Adam Silver © 2025 all rights reserved

require_relative 'drawer'
require_relative 'units'

module AdamExtensions
    module DimensionsDialog
        class << self
            attr_accessor :_dialog, :_selected_drawer_data
        end
        self._dialog = nil
        self._selected_drawer_data = {:sheet_thickness=>[], :dado_thickness=>[], :dado_depth=>[], :hidden_dado=>false}

        def self.show

            options = {
                :dialog_title => "Drawer Parameters",
                :preferences_key => "dimensions_dialog.dialog", # Unique key for persistence
                :style => UI::HtmlDialog::STYLE_UTILITY, #  For a standard dialog appearance
                #:width => 300,
                #:height => 600,
                :resizable => true
            }

            self._dialog = UI::HtmlDialog.new(options) if self._dialog.nil?
            self._dialog.set_on_closed {
                # This block will be called when the user closes the dialog
                # by clicking the X, or by using the ESC key.
                #puts "The user closed the dialog."
            }
            base_dir = __dir__.sub("box_to_drawer", "")
            html_file = File.join(base_dir, "/resources", "dimensions.html")
            self._dialog.set_file(html_file)
            self._dialog.set_size(360, 540)

            self._dialog.add_action_callback("putstr") do |action_context, str|
                puts str
            end

            # Ruby callback that JavaScript can trigger
            self._dialog.add_action_callback("updateDimensionsValues") do |action_context, sheet_thickness, dado_thickness, dado_depth|
                valid_values = false
                begin
                    sheet_thickness = Float(sheet_thickness)
                    dado_thickness = Float(dado_thickness)
                    dado_depth = Float(dado_depth)
                    valid_values = true
                rescue
                    # TODO add handler
                end
                # need to convert back to "imperial" units
                case Units::units_type
                when "metric"
                    sheet_thickness = Units::in_unit(sheet_thickness)
                    dado_thickness = Units::in_unit(dado_thickness)
                    dado_depth = Units::in_unit(dado_depth)
                when "cm_metric"
                    sheet_thickness = Units::in_unit(sheet_thickness)
                    dado_thickness = Units::in_unit(dado_thickness)
                    dado_depth = Units::in_unit(dado_depth)
                else
                    #
                end
                Drawer::Drawer::update_sheet_dado_values(sheet_thickness, dado_thickness, dado_depth)
                Drawer::Drawer.selection_to_drawers("erase,update")
            end

            self._dialog.add_action_callback("updateHiddenDado") do |action_context, hidden_dado_checked|
                Drawer::Drawer::update_hidden_dado(hidden_dado_checked)
            end

            self._dialog.add_action_callback("dom_loaded") do |action_context|
                self._update_dialog_inputs
            end

            self._dialog.set_position(300, 300) # Center the self._dialog on the screen
            self._dialog.show # Display the dialog
            # Ruby callback that JavaScript can trigger
        end # def self.show

        def self._update_dialog_inputs
            # Note: internal unit type is always "imperial"
            convert = lambda {|nums, default|
                range = []
                range << default if nums.empty?
                range << nums.first if nums.size == 1
                nums.size > 1 ? nums.minmax : range
            }
            _to_s = lambda {|range|
                range.size == 1 ? sprintf("%.2f", range.first) : sprintf("%.2f..%.2f", range.first, range.last)
            }

            sheet_thickness = convert.call(DimensionsDialog._selected_drawer_data[:sheet_thickness], Drawer::Drawer.sheet_thickness)
            dado_thickness = convert.call(DimensionsDialog._selected_drawer_data[:dado_thickness], Drawer::Drawer.dado_thickness)
            dado_depth = convert.call(DimensionsDialog._selected_drawer_data[:dado_depth], Drawer::Drawer.dado_depth)
            case Units::units_type
            when "imperial"
                units = "in"
                sheet_thickness = sheet_thickness.map {|n| Units::in_unit(n, "imperial")}
                dado_thickness = dado_thickness.map {|n| Units::in_unit(n, "imperial")}
                dado_depth = dado_depth.map {|n| Units::in_unit(n, "imperial")}
            when "metric"
                units = "mm"
                sheet_thickness = sheet_thickness.map {|n| Units::mm_unit(n, "imperial")}
                dado_thickness = dado_thickness.map {|n| Units::mm_unit(n, "imperial")}
                dado_depth = dado_depth.map {|n| Units::mm_unit(n, "imperial")}
            when "cm_metric"
                units = "cm"
                sheet_thickness = sheet_thickness.map {|n| Units::cm_unit(n, "imperial")}
                dado_thickness = dado_thickness.map {|n| Units::cm_unit(n, "imperial")}
                dado_depth = dado_depth.map {|n| Units::cm_unit(n, "imperial")}
            else
                #
            end
            self._dialog.execute_script("document.getElementById('sheet_thickness').value = '#{_to_s.call(sheet_thickness)}';")
            self._dialog.execute_script("document.getElementById('dado_thickness').value = '#{_to_s.call(dado_thickness)}';")
            self._dialog.execute_script("document.getElementById('dado_depth').value = '#{_to_s.call(dado_depth)}';")
            self._dialog.execute_script("document.getElementById('sheet_units').value = '#{units}';")
            self._dialog.execute_script("document.getElementById('dado_thickness_units').value = '#{units}';")
            self._dialog.execute_script("document.getElementById('dado_depth_units').value = '#{units}';")

            # set the image path
            base_dir = __dir__.sub("box_to_drawer", "")
            sheet_thick_image = File.join(base_dir, "/resources", "sheetThickness.svg")
            dado_thickness_image = File.join(base_dir, "/resources", "dadoWidth.svg")
            dado_depth_image = File.join(base_dir, "/resources", "dadoDepth.svg")
            self._dialog.execute_script("document.getElementById('sheet_thickness_img').src = '#{sheet_thick_image}';")
            self._dialog.execute_script("document.getElementById('dado_thickness_img').src = '#{dado_thickness_image}';")
            self._dialog.execute_script("document.getElementById('dado_depth_img').src = '#{dado_depth_image}';")
        end
        def self.close
            self._dialog&.close
            self.clear_selected_drawer_data
        end
        #@param [Sketchup::Group]
        def self.add_selected_group_data(group)
            return false unless Drawer::Drawer::is_drawer_group?(group)
            sheet_thickness = group.get_attribute(Drawer::Drawer::drawer_data_tag, "sheet_thickness")
            dado_thickness = group.get_attribute(Drawer::Drawer::drawer_data_tag, "dado_thickness")
            dado_depth = group.get_attribute(Drawer::Drawer::drawer_data_tag, "dado_depth")
            return false unless sheet_thickness&.positive? && dado_thickness&.positive? && dado_depth&.positive?
            DimensionsDialog._selected_drawer_data[:sheet_thickness] << sheet_thickness unless DimensionsDialog._selected_drawer_data[:sheet_thickness].include? sheet_thickness
            DimensionsDialog._selected_drawer_data[:dado_thickness] << dado_thickness unless DimensionsDialog._selected_drawer_data[:dado_thickness].include? dado_thickness
            DimensionsDialog._selected_drawer_data[:dado_depth] << dado_depth unless DimensionsDialog._selected_drawer_data[:dado_depth].include? dado_depth
            true
        end

        def self.clear_selected_drawer_data
            DimensionsDialog._selected_drawer_data[:sheet_thickness].clear
            DimensionsDialog._selected_drawer_data[:dado_thickness].clear
            DimensionsDialog._selected_drawer_data[:dado_depth].clear
        end

    end # module DimensionsDialog

end # module AdamExtensions
