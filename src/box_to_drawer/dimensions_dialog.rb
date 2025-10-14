#
#  dimensions_dialog.rb
#
#
#  Created by Adam Silver on 08/14/25.
#  copyright Adam Silver © 2025 all rights reserved

require 'sketchup.rb'
require_relative 'drawer'
require_relative 'box_shape'
require_relative 'units'
require_relative 'utils'
require_relative 'sel_observer'
require_relative 'err_handler'


module AdamExtensions
    module DimensionsDialog
        
        class << self
            attr_accessor :_instance
        end

        self._instance = nil

        def self.close
            self._instance&.close
            self._instance = nil
        end
        class DimensionsInputs

            def close
                @dialog&.close
            end
            #@param [String] selection_change - the identifier as to the event action
            #@param [SketchUp::Selection] selection - the selection
            def update_selected_group_data(context, selection)
                return if selection.empty?
                _clear_selected_drawer_data
                selection.each do |e|
                    if Drawer::Drawer::is_drawer_group?(e)
                        tag = Drawer::Drawer::drawer_data_tag
                        @selected_drawer_data[:sheet_thickness] |= [e.get_attribute(tag, "su-obj<sheet_thickness>")]
                        @selected_drawer_data[:dado_thickness]  |= [e.get_attribute(tag, "su-obj<dado_thickness>")]
                        @selected_drawer_data[:dado_depth]      |= [e.get_attribute(tag, "su-obj<dado_depth>")]
                    elsif BoxShape::BoxMap.is_xyz_aligned_box?(e)
                        @selected_drawer_data[:sheet_thickness] |= [@selected_drawer_data[:sheet_thickness_default]]
                        @selected_drawer_data[:dado_thickness]  |= [@selected_drawer_data[:dado_thickness_default]]
                        @selected_drawer_data[:dado_depth]      |= [@selected_drawer_data[:dado_depth_default]]
                    end
                end
                @selected_drawer_data[:sheet_thickness].empty? ? DimensionsDialog::close : _update_dialog_inputs
            end

            private
            def initialize
                @selected_drawer_data = {:sheet_thickness=>[], :sheet_thickness_default=>0.0,
                                         :dado_thickness=>[], :dado_thickness_default=>0.0,
                                         :dado_depth=>[], :dado_depth_default=>0.0}
                @dialog = nil
                SelectObserver::instance.add_observer(self, :update_selected_group_data)
                _initialize_units
                _show
            end
            def _initialize_units
                return if @selected_drawer_data[:sheet_thickness_default] > 0.0 &&
                          @selected_drawer_data[:dado_thickness_default] > 0.0 &&
                          @selected_drawer_data[:dado_depth_default] > 0.0

                json_data = Utils::get_json_data("nv_data.json")
                default_units = json_data["default_dimension"][Units::units_type]

                conversion_factor = default_units["json<conversion_factor>"]
                ["sheet_thickness", "dado_thickness", "dado_depth"].each do |id|
                    @selected_drawer_data[id.to_sym] = []
                end
                @selected_drawer_data[:sheet_thickness_default] = default_units["json<sheet_thickness>"] / conversion_factor
                @selected_drawer_data[:dado_thickness_default]  = default_units["json<dado_thickness>"] / conversion_factor
                @selected_drawer_data[:dado_depth_default]      = default_units["json<dado_depth>"] / conversion_factor
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
                    SelectObserver::quit
                    #UI.start_timer(0, false) { DimensionsDialog.close }
                }
                @dialog.set_file(Utils::get_resource_file("dimensions.html"))
                @dialog.set_size(380, 490)

                @dialog.add_action_callback("putstr") do |action_context, str|
                    puts str
                end

                @dialog.add_action_callback("updateDefaultsValues") do |action_context, sheet_thickness, dado_thickness, dado_depth|
                    begin
                        sheet_thickness = Float(sheet_thickness)
                        dado_thickness = Float(dado_thickness)
                        dado_depth = Float(dado_depth)
                        valid_values = true
                    rescue
                        # TODO add handler
                    end
                    json_data = Utils::get_json_data("nv_data.json")
                    json_data["default_dimension"][Units::units_type]["json<sheet_thickness>"] = sheet_thickness
                    json_data["default_dimension"][Units::units_type]["json<dado_thickness>"] = dado_thickness
                    json_data["default_dimension"][Units::units_type]["json<dado_depth>"] = dado_depth
                    Utils::write_pretty_json_data("nv_data.json", json_data)
                end
                # Ruby callback that JavaScript can trigger
                @dialog.add_action_callback("updateDimensionsValues") do |action_context, sheet_thickness, dado_thickness, dado_depth|
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
                             :dado_depth => dado_depth }
                    if Drawer::Drawer.is_valid_drawer_data?(data)
                        Drawer::Drawer.selection_to_drawers( "erase,update", data)
                        UI.start_timer(0, false) { DimensionsDialog.close }
                    end
                end

                @dialog.add_action_callback("closeDialog") do |action_context|
                    UI.start_timer(0, false) { DimensionsDialog.close }
                end

                @dialog.add_action_callback("dom_loaded") do |action_context|
                    update_selected_group_data('intialize', Sketchup.active_model.selection)
                    _update_dialog_inputs
                end

                @dialog.add_action_callback("new_drawer_type") do |action_context, value|
                    Drawer::Drawer.new_type_selection(value)
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

                @dialog.execute_script("document.getElementById('drawer_type_select').value = '#{Drawer::Drawer.drawer_type}';")
            end

            def _clear_selected_drawer_data
                [:sheet_thickness, :dado_thickness, :dado_depth].each {|id| @selected_drawer_data[id].clear}
            end

        end # class DimensionsInputs

        def self.install
            return unless Drawer::Drawer::selection_to_drawers("test")
            self._instance = DimensionsInputs.new if self._instance.nil?
        end

    end # module DimensionsDialog

end # module AdamExtensions
