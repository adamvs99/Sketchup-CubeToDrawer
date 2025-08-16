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
                      <script>
                        sheet_thickness.addEventListener('input', function() {
                            this.value = this.value.replace(/[^a-zA-Z\s]/g, '')
                        });
                      </script>
                      <title>Cube to Drawer Parameters</title>
                      <style>
                        body { font-family: sans-serif; }
                        button { padding: 10px 20px; }
                        .center {
                          text-align: center;
                          border: 3px solid green;
                        }
                      </style>
                    </head>
                    <body>
                      <h3>Thickness of drawer panels</h3>
                      <div class="center">
                        <p>
                            <label for="sheet_thickness">Sheet thickness:</label>
                            <input type="text" id="sheet_thickness" name="sheet_thickness"
                                    pattern="^[-+]?([0-9]*\.[0-9]+|[0-9]+\.?)([eE][-+]?[0-9]+)?$">
                        </p>
                        <p>
                           <label for="dado_width">Dado thickness:</label>
                           <input type="text" id="dado_width" name="dado_width"
                                   pattern="^[-+]?([0-9]*\.[0-9]+|[0-9]+\.?)([eE][-+]?[0-9]+)?$">
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
                dialog.execute_script("document.getElementById('sheet_thickness').value = '#{sheet_thickness}';")
                dialog.execute_script("document.getElementById('dado_width').value = '#{dado_width}';")
            end

            dialog.set_position(300, 300) # Center the dialog on the screen
            dialog.show # Display the dialog
            # Ruby callback that JavaScript can trigger
        end # def self.show
    end # module UnitsDialog
end # module AdamExtensions
