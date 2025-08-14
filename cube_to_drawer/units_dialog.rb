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
                      <h1>Thickness of drawer panels</h1>
                      <p>This is a modeless dialog.</p>
                      <button onclick="sketchup.say_hello()">Say Hello</button>
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
            dialog.add_action_callback("say_hello") do |_|
                puts "Hello from Ruby, invoked by JavaScript!"
            end

            dialog.center # Center the dialog on the screen
            dialog.show # Display the dialog
        end # def self.show
    end # module UnitsDialog
end # module AdamExtensions

# To show the dialog, you can call:
# MyExtension::MyDialog.show
