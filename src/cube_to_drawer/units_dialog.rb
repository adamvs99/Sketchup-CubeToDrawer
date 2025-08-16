#
#  units_dialog.rb
#
#
#  Created by Adam Silver on 08/14/25.
#  copyright Adam Silver © 2025 all rights reserved

require_relative 'main'

module AdamExtensions
    module UnitsDialog
        def self.show
            html = <<-HTML
            <!DOCTYPE html>
                <html>
                    <head>
                      <title>Cube to Drawer Parameters</title>
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
                      </style>
                    </head>
                    <body>
                      <h3 style="text-align: center;">Cube to Drawer Parameters</h3>
                      <div class="center">
                        <h3>Thickness of drawer panels</h3>
                        <p>
                            <label for="sheet_thickness">Sheet thickness:</label>
                            <input class="center_editable" type="text" id="sheet_thickness" name="sheet_thickness">
                            <input class="unit_noneditable" type="text" id="sheet_units" name="sheet_units">
                        </p>
                        <p>
                           <label for="dado_width">Dado thickness:</label>
                           <input class="center_editable" type="text" id="dado_width" name="dado_width" readonly="readonly">
                           <input class="unit_noneditable" type="text" id="dado_units" name="dado_units" readonly="readonly">
                        </p>
                        
                        <p>
                            <button onclick="sendDataToSketchUp()">Update</button>
                        </p>
                      </div>
                      <script>
                         function sendDataToSketchUp() {
                          var sheetValue = document.getElementById('sheet_thickness').value;
                          var dadoValue = document.getElementById('dado_width').value;

                          sketchup.updateUnitsDialogValues(sheetValue, dadoValue); // 'updateDialogValues' is a Ruby callback
                        }
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
                        document.addEventListener('DOMContentLoaded', function() {
                          sketchup.dom_loaded(); 
                        });                     
                      </script>
                    </body>
                </html>
            HTML

            options = {
                :dialog_title => "My Modeless Dialog",
                :preferences_key => "units_dialog.dialog", # Unique key for persistence
                :style => UI::HtmlDialog::STYLE_UTILITY, #  For a standard dialog appearance
                :resizable => false,
                :width => 350,
                :height => 400
            }

            dialog = UI::HtmlDialog.new(options)
            dialog.set_html(html)

            # Ruby callback that JavaScript can trigger
            dialog.add_action_callback("updateUnitsDialogValues") do |action_context, sheet_value, dado_value|
                CubeToDrawer.update_sheet_dado_values(sheet_value, dado_value)
            end

            dialog.add_action_callback("dom_loaded") do |action_context|
                sheet_thickness = sprintf("%.2f", CubeToDrawer._sheet_thickness)
                dado_width = sprintf("%.2f", CubeToDrawer._dado_thickness)
                units = CubeToDrawer._units_type == "metric" ? "mm" : "in"
                dialog.execute_script("document.getElementById('sheet_thickness').value = '#{sheet_thickness}';")
                dialog.execute_script("document.getElementById('dado_width').value = '#{dado_width}';")
                dialog.execute_script("document.getElementById('sheet_units').value = '#{units}';")
                dialog.execute_script("document.getElementById('dado_units').value = '#{units}';")
            end

            dialog.set_position(300, 300) # Center the dialog on the screen
            dialog.show # Display the dialog
            # Ruby callback that JavaScript can trigger
        end # def self.show
    end # module UnitsDialog
end # module AdamExtensions
