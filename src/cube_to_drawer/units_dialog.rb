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
                        .images {
                          vertical-align: middle;
                          horiz-align: center;
                          height: 100%;
                          margin: 0 auto;
                          width: 100%;
                          position: relative;
                        }
                        img { display: none; }
                      </style>
                    </head>
                    <body>
                      <h3 style="text-align: center;">Cube to Drawer Parameters</h3>
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
                            <button onclick="sendDataToSketchUp()" tabindex="0">Update</button>
                        </p>
                      </div>
                      <div class="images">
                          <img src="../../resources/sheetThickness.svg" id="sheet_thickness_img" alt="sheetThickness">
                          <img src="../../resources/dadoWidth.svg" id="dado_width_img" alt="dadoWidth">
                          <img src="../../resources/dadoDepth.svg" id="dado_depth_img" alt="dadoDepth">
                      </div>
                      <script>
                         function sendDataToSketchUp() {
                          var sheetThickness = document.getElementById('sheet_thickness').value;
                          var dadoWidth = document.getElementById('dado_width').value;
                          var dadoDepth = document.getElementById('dado_depth').value;

                          sketchup.updateUnitsDialogValues(sheetThickness, dadoWidth, dadoDepth); // 'updateDialogValues' is a Ruby callback
                        }
                        
                        document.getElementById("sheet_thickness").addEventListener('focusin', function() {
                            document.getElementById("sheet_thickness_img").style.display="block";
                        });
                        document.getElementById("sheet_thickness").addEventListener('focusout', function() {
                            document.getElementById("sheet_thickness_img").style.display="none";
                        });
                        document.getElementById("dado_width").addEventListener('focusin', function() {sketchup.putstr("dado_width in focus")
                            document.getElementById("dado_width_img").style.display="block";
                         });
                        document.getElementById("dado_width").addEventListener('focusout', function() {
                            document.getElementById("dado_width_img").style.display="none";
                        });
                        document.getElementById("dado_depth").addEventListener('focusin', function() {
                            document.getElementById("dado_depth_img").style.display = "block";
                         });
                        document.getElementById("dado_depth").addEventListener('focusout', function() {
                            document.getElementById("dado_depth_img").style.display = "none";
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
                #:width => 320,
                :height => 600,
                :resizable => false
            }

            dialog = UI::HtmlDialog.new(options)
            dialog.set_html(html)
            dialog.set_size(320, 380)

            dialog.add_action_callback("putstr") do |action_context, str|
                puts str
            end

            # Ruby callback that JavaScript can trigger
            dialog.add_action_callback("updateUnitsDialogValues") do |action_context, sheet_thickness, dado_width, dado_depth|
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
                case CubeToDrawer._units_type
                when "metric"
                    sheet_thickness = Utils.in_unit(sheet_thickness)
                    dado_width = Utils.in_unit(dado_width)
                    dado_depth = Utils.in_unit(dado_depth)
                when "cm_metric"
                    sheet_thickness = Utils.in_unit(sheet_thickness)
                    dado_width = Utils.in_unit(dado_width)
                    dado_depth = Utils.in_unit(dado_depth)
                else
                    #
                end
                CubeToDrawer.update_sheet_dado_values(sheet_thickness, dado_width, dado_depth)
            end

            dialog.add_action_callback("updateHiddenDado") do |action_context, hidden_dado_checked|
                CubeToDrawer.update_hidden_dado(hidden_dado_checked)
            end

            dialog.add_action_callback("dom_loaded") do |action_context|
                # Note: internal unit type is always "imperial"
                case CubeToDrawer._units_type
                when "imperial"
                    units = "in"
                    sheet_thickness = sprintf("%.2f", CubeToDrawer._sheet_thickness)
                    dado_width = sprintf("%.2f", CubeToDrawer._dado_thickness)
                    dado_depth = sprintf("%.2f", CubeToDrawer._dado_depth)
                when "metric"
                    units = "mm"
                    sheet_thickness = sprintf("%.2f", Utils.mm_unit(CubeToDrawer._sheet_thickness, "imperial"))
                    dado_width = sprintf("%.2f", Utils.mm_unit(CubeToDrawer._dado_thickness, "imperial"))
                    dado_depth = sprintf("%.2f", Utils.mm_unit(CubeToDrawer._dado_depth, "imperial"))
                when "cm_metric"
                    units = "mm"
                    sheet_thickness = sprintf("%.2f", Utils.cm_unit(CubeToDrawer._sheet_thickness, "imperial"))
                    dado_width = sprintf("%.2f", Utils.cm_unit(CubeToDrawer._dado_thickness, "imperial"))
                    dado_depth = sprintf("%.2f", Utils.cm_unit(CubeToDrawer._dado_depth, "imperial"))
                else
                    #
                end
                dialog.execute_script("document.getElementById('sheet_thickness').value = '#{sheet_thickness}';")
                dialog.execute_script("document.getElementById('dado_width').value = '#{dado_width}';")
                dialog.execute_script("document.getElementById('dado_depth').value = '#{dado_depth}';")
                dialog.execute_script("document.getElementById('sheet_units').value = '#{units}';")
                dialog.execute_script("document.getElementById('dado_width_units').value = '#{units}';")
                dialog.execute_script("document.getElementById('dado_depth_units').value = '#{units}';")
            end

            dialog.set_position(300, 300) # Center the dialog on the screen
            dialog.show # Display the dialog
            # Ruby callback that JavaScript can trigger
        end # def self.show
    end # module UnitsDialog
end # module AdamExtensions
