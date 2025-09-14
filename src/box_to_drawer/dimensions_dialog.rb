#
#  dimensions_dialog.rb
#
#
#  Created by Adam Silver on 08/14/25.
#  copyright Adam Silver © 2025 all rights reserved

require_relative 'drawer'
require_relative 'units'
require_relative 'utils'

module AdamExtensions
    module DimensionsDialog
        
        class << self
            attr_accessor :_instance
        end

        self._instance = nil

        def self.close
            self._instance&.close
        end
        class DimensionsInputs

            def close
                @dialog&.close
            end

            #@param [Sketchup::Group]
            def add_selected_group_data(group)
                return false unless Drawer::Drawer::is_drawer_group?(group)
                sheet_thickness = group.get_attribute(Drawer::Drawer::drawer_data_tag, "su-obj<sheet_thickness>")
                dado_thickness = group.get_attribute(Drawer::Drawer::drawer_data_tag, "su-obj<dado_thickness>")
                dado_depth = group.get_attribute(Drawer::Drawer::drawer_data_tag, "su-obj<dado_depth>")
                return false unless sheet_thickness&.positive? && dado_thickness&.positive? && dado_depth&.positive?
                # add unique values to the list...
                @selected_drawer_data[:sheet_thickness] |= [sheet_thickness]
                @selected_drawer_data[:dado_thickness] |= [dado_thickness]
                @selected_drawer_data[:dado_depth] |= [dado_depth]
                true
            end

            private
            def initialize
                @selected_drawer_data = {:sheet_thickness=>[], :sheet_thickness_default=>0.0,
                                         :dado_thickness=>[], :dado_thickness_default=>0.0,
                                         :dado_depth=>[], :dado_depth_default=>0.0,
                                         :hidden_dado=>false}
                @dialog = nil
                _initialize_units
                _show
            end
            def _initialize_units
                # this gets called when a drawer is created
                # gate this if already there are already drawers
                # created
                return if @selected_drawer_data[:sheet_thickness_default] > 0.0 &&
                          @selected_drawer_data[:dado_thickness_default] > 0.0 &&
                          @selected_drawer_data[:dado_depth_default] > 0.0
                json_data = File.read(Utils::get_resource_file("nv_data.json"))
                json_data = JSON.parse(json_data)
                default_units = json_data["default_dimension"][Units::units_type]

                conversion_factor = default_units["json<conversion_factor>"]
                @selected_drawer_data[:sheet_thickness_default] = default_units["json<sheet_thickness>"] / conversion_factor
                @selected_drawer_data[:dado_thickness_default] = default_units["json<dado_thickness>"] / conversion_factor
                @selected_drawer_data[:dado_depth_default] = default_units["json<dado_depth>"] / conversion_factor
            end

            def _show

                options = {
                    :dialog_title => "Drawer Parameters",
                    :preferences_key => "dimensions_dialog.dialog", # Unique key for persistence
                    :style => UI::HtmlDialog::STYLE_UTILITY, #  For a standard dialog appearance
                    #:width => 300,
                    #:height => 600,
                    :resizable => true
                }

                @dialog = UI::HtmlDialog.new(options) if @dialog.nil?
                @dialog.set_on_closed {
                    @dialog = nil
                    SelectObserver::quit
                    UI.start_timer(0, false) { DimensionsDialog._instance = nil }
                }
                @dialog.set_file(Utils::get_resource_file("dimensions.html"))
                @dialog.set_size(400, 540)

                @dialog.add_action_callback("putstr") do |action_context, str|
                    puts str
                end

                @dialog.add_action_callback("updateDefaultsValues") do |action_context, sheet_thickness, dado_thickness, dado_depth, hidden_dado|
                    begin
                        sheet_thickness = Float(sheet_thickness)
                        dado_thickness = Float(dado_thickness)
                        dado_depth = Float(dado_depth)
                        valid_values = true
                    rescue
                        # TODO add handler
                    end
                    json_data = File.read(Utils::get_resource_file("nv_data.json"))
                    json_data = JSON.parse(json_data)
                    json_data["default_dimension"][Units::units_type]["json<sheet_thickness>"] = sheet_thickness
                    json_data["default_dimension"][Units::units_type]["json<dado_thickness>"] = dado_thickness
                    json_data["default_dimension"][Units::units_type]["json<dado_depth>"] = dado_depth
                    File.write(Utils::get_resource_file("nv_data.json"), json_data.to_json)
                end
                # Ruby callback that JavaScript can trigger
                @dialog.add_action_callback("updateDimensionsValues") do |action_context, sheet_thickness, dado_thickness, dado_depth, hidden_dado|
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
                    data = { :sheet_thickness => sheet_thickness,
                             :dado_thickness => dado_thickness,
                             :dado_depth => dado_depth,
                             :hidden_dado => hidden_dado }
                    Drawer::Drawer.selection_to_drawers( "erase,update", data)
                    close
                    SelectObserver::quit
                end

                @dialog.add_action_callback("closeDialog") do |action_context|
                    close
                end

                @dialog.add_action_callback("dom_loaded") do |action_context|
                    _update_dialog_inputs
                end

                @dialog.set_position(300, 300) # Center the @dialog on the screen
                @dialog.show # Display the dialog
                # Ruby callback that JavaScript can trigger
            end # def self.show

            def _update_dialog_inputs
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
                data = @selected_drawer_data
                sheet_thickness = convert.call(data[:sheet_thickness], data[:sheet_thickness_default])
                dado_thickness = convert.call(data[:dado_thickness], data[:dado_thickness_default])
                dado_depth = convert.call(data[:dado_depth], data[:dado_depth_default])
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

                @dialog.execute_script("setInitialValue('sheet_thickness', '#{_to_s.call(sheet_thickness)}');")
                @dialog.execute_script("setInitialValue('dado_thickness', '#{_to_s.call(dado_thickness)}');")
                @dialog.execute_script("setInitialValue('dado_depth', '#{_to_s.call(dado_depth)}');")

                ["sheet_units", "dado_thickness_units", "dado_depth_units"].each {|id|
                    @dialog.execute_script("document.getElementById('#{id}').value = '#{units}';")
                }

                # set the image path
                sheet_thick_image = Utils::get_resource_file("sheetThickness.svg")
                dado_thickness_image = Utils::get_resource_file("dadoWidth.svg")
                dado_depth_image = Utils::get_resource_file("dadoDepth.svg")
                @dialog.execute_script("document.getElementById('sheet_thickness_img').src = '#{sheet_thick_image}';")
                @dialog.execute_script("document.getElementById('dado_thickness_img').src = '#{dado_thickness_image}';")
                @dialog.execute_script("document.getElementById('dado_depth_img').src = '#{dado_depth_image}';")
            end

            def _clear_selected_drawer_data
                @selected_drawer_data[:sheet_thickness].clear
                @selected_drawer_data[:dado_thickness].clear
                @selected_drawer_data[:dado_depth].clear
                @selected_drawer_data[:dado_depth].clear
            end

        end # class DimensionsInputs

        def self.install
            return unless Drawer::Drawer::selection_to_drawers("test")
            self._instance = DimensionsInputs.new if self._instance.nil?
        end

    end # module DimensionsDialog

end # module AdamExtensions
