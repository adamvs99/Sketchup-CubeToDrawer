#
#  units_dialog.rb
#
#
#  Created by Adam Silver on 08/14/25.
#  copyright Adam Silver © 2025 all rights reserved

require_relative 'drawer'
require_relative 'units'

module AdamExtensions
    module UnitsDialog
        class << self
            attr_accessor :_dialog, :_selected_drawer_data
        end
        self._dialog = nil
        self._selected_drawer_data = {:sheet_thickness=>[], :dado_thickness=>[], :dado_depth=>[], :hidden_dado=>false}

        def self.show
            # re-show show if already instantiated but not visible
            # makes this a singleton...
            return if self._dialog&.visible?
            self._dialog.show unless self._dialog.nil?

            html = <<-HTML
            <!DOCTYPE html>
                <html>
                    <head>
                      <title>Box to Drawer Parameters</title>
                      <style>
                        body { font-family: sans-serif; }
                        button { padding: 10px 20px; }
                        .center {
                          text-align: center;
                          border: 3px solid green;
                        }
                        .center_editable {
                          text-align: center;
                          width: 60px;
                        }
                        .unit_noneditable {
                          text-align: left;
                          width: 30px;
                          border: none;
                          color: darkblue;
                          font-weight: bold;
                        }
                        .images {
                          vertical-align: middle;
                          horiz-align: center;
                          height: 60%;
                          margin: auto;
                          margin-top: 10px;
                          width: 60%;
                          position: relative;
                        }
                        img { display: none; }
                      </style>
                    </head>
                    <body>
                      <h3 style="text-align: center;">Box to Drawer Parameters</h3>
                      <div class="center">
                        <h3>Thickness of drawer panels</h3>
                        <p>
                            <label for="sheet_thickness">Sheet Thickness:</label>
                            <input class="center_editable" type="text" id="sheet_thickness" name="sheet_thickness" tabindex="1">
                            <input class="unit_noneditable" type="text" id="sheet_units" name="sheet_units" readonly="readonly" tabindex="-1">
                        </p>
                        <p>
                           <label for="dado_width">Dado Thickness:</label>
                           <input class="center_editable" type="text" id="dado_width" name="dado_width" tabindex="2">
                           <input class="unit_noneditable" type="text" id="dado_width_units" name="dado_width_units" readonly="readonly" tabindex="-1">
                        </p>
                         <p>
                           <label for="dado_depth">Dado Depth:</label>
                           <input class="center_editable" type="text" id="dado_depth" name="dado_depth" tabindex="3">
                           <input class="unit_noneditable" type="text" id="dado_depth_units" name="dado_depth_units" readonly="readonly" tabindex="-1">
                        </p>
                        
                         <p>
                           <label for="hidden_dado">Hidden Dado:</label>
                           <input class="center_editable" type="checkbox" id="hidden_dado" name="hidden_dado" value="hidden_dado" tabindex="4">
                        </p>
                       
                        <p>
                            <button onclick="sendDataToSketchUp()" id="update_button" tabindex="0">Update</button>
                        </p>
                      </div>
                      <div class="images">
                          <img id="sheet_thickness_img" alt="sheetThickness">
                          <img id="dado_width_img" alt="dadoWidth">
                          <img id="dado_depth_img" alt="dadoDepth">
                      </div>
                      <script>
                        function sendDataToSketchUp() {
                            var sheetThickness = document.getElementById('sheet_thickness').value;
                            var dadoWidth = document.getElementById('dado_width').value;
                            var dadoDepth = document.getElementById('dado_depth').value;

                            sketchup.updateUnitsDialogValues(sheetThickness, dadoWidth, dadoDepth); // 'updateDialogValues' is a Ruby callback
                        }
                        
                         function inputNumberFormat(elementID) {
                            const inputElement = document.getElementById(elementID);
                            var inputValue = inputElement.value;
                            inputValue = inputValue.trim();
                            const numberValue = parseFloat(inputValue);
                            if (!isNaN(numberValue)) {
                                inputElement.style = "color: black;"
                                inputElement.value = numberValue.toFixed(2);
                                document.getElementById("update_button").disabled = false;
                            } else {
                                inputElement.style = "color: red;"
                                document.getElementById("update_button").disabled = true;
                                console.warn("Input is not a valid number.");
                            }
                       }

// Example HTML for the input field
// <input type="text" id="myInput" onblur="formatInputToTwoDecimals()">
                       document.getElementById("sheet_thickness").addEventListener('focusin', function() {
                            document.getElementById("sheet_thickness_img").style.display="block";
                        });
                        document.getElementById("sheet_thickness").addEventListener('focusout', function() {
                            document.getElementById("sheet_thickness_img").style.display="none";
                            inputNumberFormat("sheet_thickness");
                        });
                        document.getElementById("dado_width").addEventListener('focusin', function() {sketchup.putstr("dado_width in focus")
                            document.getElementById("dado_width_img").style.display="block";
                         });
                        document.getElementById("dado_width").addEventListener('focusout', function() {
                            document.getElementById("dado_width_img").style.display="none";
                            inputNumberFormat("dado_width");
                        });
                        document.getElementById("dado_depth").addEventListener('focusin', function() {
                            document.getElementById("dado_depth_img").style.display = "block";
                         });
                        document.getElementById("dado_depth").addEventListener('focusout', function() {
                            document.getElementById("dado_depth_img").style.display = "none";
                            inputNumberFormat("dado_depth");
                         });
                        
                        document.getElementById("sheet_thickness").addEventListener('keypress', function(event) {
                            if (!/[0-9.]/.test(event.key)) {
                                event.preventDefault(); // Prevent non-numeric characters
                            }
                        });
                        document.getElementById("dado_width").addEventListener('keypress', function(event) {
                            if (!/[0-9.]/.test(event.key)) {
                                event.preventDefault(); // Prevent non-numeric characters
                            }
                        });
                        document.getElementById("dado_depth").addEventListener('keypress', function(event) {
                            if (!/[0-9.]/.test(event.key)) {
                                event.preventDefault(); // Prevent non-numeric characters
                            }
                        });
                        document.getElementById("hidden_dado").addEventListener('change', function() {
                            sketchup.updateHiddenDado(this.checked)
                        });
                        document.addEventListener('DOMContentLoaded', function() {
                          sketchup.dom_loaded(); 
                        });                     
                      </script>
                    </body>
                </html>
            HTML

            options = {
                :dialog_title => "Drawer Parameters",
                :preferences_key => "units_dialog.dialog", # Unique key for persistence
                :style => UI::HtmlDialog::STYLE_UTILITY, #  For a standard dialog appearance
                #:width => 300,
                #:height => 600,
                :resizable => true
            }

            self._dialog = UI::HtmlDialog.new(options)
            self._dialog.set_on_closed {
                # This block will be called when the user closes the dialog
                # by clicking the X, or by using the ESC key.
                #puts "The user closed the dialog."
            }
            self._dialog.set_html(html)
            self._dialog.set_size(290, 540)

            self._dialog.add_action_callback("putstr") do |action_context, str|
                puts str
            end

            # Ruby callback that JavaScript can trigger
            self._dialog.add_action_callback("updateUnitsDialogValues") do |action_context, sheet_thickness, dado_width, dado_depth|
                valid_values = false
                begin
                    sheet_thickness = Float(sheet_thickness)
                    dado_width = Float(dado_width)
                    dado_depth = Float(dado_depth)
                    valid_values = true
                rescue
                    # TODO add handler
                end
                # need to convert back to "imperial" units
                case Units::units_type
                when "metric"
                    sheet_thickness = Units::in_unit(sheet_thickness)
                    dado_width = Units::in_unit(dado_width)
                    dado_depth = Units::in_unit(dado_depth)
                when "cm_metric"
                    sheet_thickness = Units::in_unit(sheet_thickness)
                    dado_width = Units::in_unit(dado_width)
                    dado_depth = Units::in_unit(dado_depth)
                else
                    #
                end
                Drawer::Drawer::update_sheet_dado_values(sheet_thickness, dado_width, dado_depth)
                Drawer::Drawer.selection_to_drawers("erase")
            end

            self._dialog.add_action_callback("updateHiddenDado") do |action_context, hidden_dado_checked|
                Drawer::Drawer::update_hidden_dado(hidden_dado_checked)
            end

            self._dialog.add_action_callback("dom_loaded") do |action_context|
                # Note: internal unit type is always "imperial"
                sheet_thickness = Drawer::Drawer.sheet_thickness
                dado_width = Drawer::Drawer.dado_thickness
                dado_depth = Drawer::Drawer.dado_depth
                case Units::units_type
                when "imperial"
                    units = "in"
                    sheet_thickness = sprintf("%.2f", sheet_thickness)
                    dado_width = sprintf("%.2f", dado_width)
                    dado_depth = sprintf("%.2f", dado_depth)
                when "metric"
                    units = "mm"
                    sheet_thickness = sprintf("%.2f", Units::mm_unit(sheet_thickness, "imperial"))
                    dado_width = sprintf("%.2f", Units::mm_unit(dado_width, "imperial"))
                    dado_depth = sprintf("%.2f", Units::mm_unit(dado_depth, "imperial"))
                when "cm_metric"
                    units = "mm"
                    sheet_thickness = sprintf("%.2f", Units::cm_unit(sheet_thickness, "imperial"))
                    dado_width = sprintf("%.2f", Units::cm_unit(dado_width, "imperial"))
                    dado_depth = sprintf("%.2f", Units::cm_unit(dado_depth, "imperial"))
                else
                    #
                end
                self._dialog.execute_script("document.getElementById('sheet_thickness').value = '#{sheet_thickness}';")
                self._dialog.execute_script("document.getElementById('dado_width').value = '#{dado_width}';")
                self._dialog.execute_script("document.getElementById('dado_depth').value = '#{dado_depth}';")
                self._dialog.execute_script("document.getElementById('sheet_units').value = '#{units}';")
                self._dialog.execute_script("document.getElementById('dado_width_units').value = '#{units}';")
                self._dialog.execute_script("document.getElementById('dado_depth_units').value = '#{units}';")

                # set the image path
                base_dir = __dir__.sub("box_to_drawer", "")
                sheet_thick_image = File.join(base_dir, "/resources", "sheetThickness.svg")
                dado_width_image = File.join(base_dir, "/resources", "dadoWidth.svg")
                dado_depth_image = File.join(base_dir, "/resources", "dadoDepth.svg")
                self._dialog.execute_script("document.getElementById('sheet_thickness_img').src = '#{sheet_thick_image}';")
                self._dialog.execute_script("document.getElementById('dado_width_img').src = '#{dado_width_image}';")
                self._dialog.execute_script("document.getElementById('dado_depth_img').src = '#{dado_depth_image}';")
            end

            self._dialog.set_position(300, 300) # Center the self._dialog on the screen
            self._dialog.show # Display the dialog
            # Ruby callback that JavaScript can trigger
        end # def self.show

        #@param [Sketchup::Group]
        def self.add_unique_selected_drawer_data(group)
            return false unless Drawer::Drawer::is_drawer_group?(group)
            sheet_thickness = group.get_attribute(Drawer::Drawer::drawer_data_tag, "sheet_thickness")
            dado_thickness = group.get_attribute(Drawer::Drawer::drawer_data_tag, "dado_thickness")
            dado_depth = group.get_attribute(Drawer::Drawer::drawer_data_tag, "dado_depth")
            return false unless sheet_thickness&.positive? && dado_thickness&.positive? && dado_depth&.positive?
            UnitsDialog._selected_drawer_data[:sheet_thickness] << sheet_thickness unless UnitsDialog._selected_drawer_data[:sheet_thickness].include? sheet_thickness
            UnitsDialog._selected_drawer_data[:dado_thickness] << dado_thickness unless UnitsDialog._selected_drawer_data[:dado_thickness].include? dado_thickness
            UnitsDialog._selected_drawer_data[:dado_depth] << dado_depth unless UnitsDialog._selected_drawer_data[:dado_depth].include? dado_depth
            true
        end

        def self.clear_selected_drawer_data
            UnitsDialog._selected_drawer_data[:sheet_thickness].clear
            UnitsDialog._selected_drawer_data[:dado_thickness].clear
            UnitsDialog._selected_drawer_data[:dado_depth].clear
        end

    end # module UnitsDialog

end # module AdamExtensions
