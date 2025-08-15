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
                           <label for="dado_thickness">Dado thickness:</label>
                           <input type="text" id="dado_thickness" name="dado_thickness"
                                   pattern="^[-+]?([0-9]*\.[0-9]+|[0-9]+\.?)([eE][-+]?[0-9]+)?$">
                        </p>
                        <p>
                            <button onclick="sendDataToSketchUp()">Update</button>
                        </p>
                      </div>
                      <script>
                        function sendDataToSketchUp() {
                           var sheetValue = document.getElementById('sheet_thickness').value;
                           var dadoValue = document.getElementById('dado_thickness').value;

                           sketchup.updateUnitsDialogValues(sheetValue, dadoValue); // 'updateDialogValues' is a Ruby callback
                        }
                      </script>
                    </body>
                </html>
            HTML

            options = {
                :dialog_title => "My Modeless Dialog",
                :preferences_key => "units_dialog.dialog", # Unique key for persistence
                :style => UI::HtmlDialog::STYLE_UTILITY, #  For a standard dialog appearance
                :width => 400,
                :height => 400
            }

            dialog = UI::HtmlDialog.new(options)
            dialog.set_html(html)

            # Ruby callback that JavaScript can trigger
            dialog.add_action_callback("updateUnitsDialogValues") do |action_context, sheet_value, dado_value|
                CubeToDrawer.update_sheet_dado_values(sheet_value, dado_value)
            end

            dialog.center # Center the dialog on the screen
            dialog.show # Display the dialog
        end # def self.show
    end # module UnitsDialog
end # module AdamExtensions
