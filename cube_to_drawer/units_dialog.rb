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
                      </style>
                    </head>
                    <body>
                      <h2>Thickness of drawer panels</h2>
                      <p>This is a modeless dialog.</p>
                      <label for="sheet_thickness">Sheet thickness:</label>
                      <input change="sketchup.on_change_sheet_thickness" id="sheet_thickness" name="sheet_thickness"
                             step="any" type="number">
                    </body>
                </html>
            HTML

            options = {
                :dialog_title => "My Modeless Dialog",
                :preferences_key => "units_dialog.dialog", # Unique key for persistence
                :style => UI::HtmlDialog::STYLE_UTILITY #  For a standard dialog appearance
            }

            dialog = UI::HtmlDialog.new(options)
            dialog.set_html(html)

            # Ruby callback that JavaScript can trigger
            dialog.add_action_callback("on_change_sheet_thickness") do |_|
                CubeToDrawer.on_change_sheet_thickness(18)
            end

            dialog.center # Center the dialog on the screen
            dialog.show # Display the dialog
        end # def self.show
    end # module UnitsDialog
end # module AdamExtensions
#pattern="^[-+]?([0-9]*\.[0-9]+|[0-9]+\.?)([eE][-+]?[0-9]+)?$"
# To show the dialog, you can call:
# MyExtension::MyDialog.show
