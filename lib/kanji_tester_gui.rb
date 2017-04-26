require "pathname"
require "gtk3"
require "yaml"

=begin
A simple GTK3 kanji tester.
=end

class KanjiTesterGUI < Gtk::Window
  @kanjis    # Kanji list
  @question  # Current question
  @solutions # Solutions from soluzioni.yaml

  # Constructor. It is supposed to initialize and show the GUI.
  def initialize
    super

    @kanjis = Array.new
    @question = ""
    @solutions = Hash.new

    begin
      @solutions = YAML.load_file "#{Pathname.new($0).realpath.dirname}" +
                                  "/resources/soluzioni.yaml"
    rescue
      @solutions = Hash.new
    end
    
    # Quit icon:
    signal_connect "destroy" do
      Gtk.main_quit
    end

    # Window properties:
    set_title "Kanji Tester"
    set_border_width 10
    set_default_size 585, 400
    set_window_position :center
    set_resizable false

    # Main grid container:
    grid = Gtk::Grid.new 
    grid.set_column_spacing 10
    grid.set_row_spacing 10
    grid.set_property "row-homogeneous", true
    grid.set_property "column-homogeneous", true

    # Area where both te kanji will be written by the user:
    in_scroller = Gtk::ScrolledWindow.new
    in_view = Gtk::TextView.new
    in_view.editable = true
    in_buffer = Gtk::TextBuffer.new
    in_view.set_buffer in_buffer
    # Apparently, this can fail:
    begin
      in_view.set_monospace  true
    rescue
      # Nothing to do here, really.
    end
    in_scroller.add in_view
    grid.attach in_scroller, 0, 0, 3, 3

    # Instructions:
    header = Gtk::Label.new "↑↑↑ Incolla i kanji da provare qua sopra ↑↑↑\n" +
                            "↓↓↓ Le domande appariranno qua sotto ↓↓↓"
    grid.attach header, 0, 3, 2, 1

    # Start button:
    start_test = Gtk::Button.new :label => "Inizia il test!"
    grid.attach start_test, 2, 3, 1, 1

    # Output area:
    out_scroller = Gtk::ScrolledWindow.new
    out_view = Gtk::TextView.new
    out_view.editable = false
    out_buffer = Gtk::TextBuffer.new
    out_view.set_buffer out_buffer
    # Apparently, this can fail:
    begin
      text_view.set_monospace  true
    rescue
      # Nothing to do here, really.
    end
    out_scroller.add out_view
    grid.attach out_scroller, 0, 4, 3, 3

    # Make out_scroller automatically move to the bottom:
    out_view.signal_connect("size-allocate") do |widget, step, arg2|
      out_scroller.vadjustment.value = out_scroller.vadjustment.upper -
                                       out_scroller.vadjustment.page_size
    end

    # Yes button:
    yes_test = Gtk::Button.new :label => "Sì!"
    yes_test.sensitive = false
    grid.attach yes_test, 0, 7, 1, 1

    # No button:
    no_test = Gtk::Button.new :label => "No..."
    no_test.sensitive = false
    grid.attach no_test, 1, 7, 1, 1

    # Stop button:
    stop_test = Gtk::Button.new :label => "Fermiamoci."
    stop_test.sensitive = false
    grid.attach stop_test, 2, 7, 1, 1

    ### SIGNALS:

    # Start signal:
    start_test.signal_connect "clicked" do
      startTest :view_in => in_view,
                :view_out => out_view,
                :yes => yes_test,
                :no => no_test,
                :stop => stop_test,
                :start => start_test
    end

    # Yes signal:
    yes_test.signal_connect "clicked" do
      yesTest :view_in => in_view,
              :view_out => out_view,
              :yes => yes_test,
              :no => no_test,
              :stop => stop_test,
              :start => start_test
    end

    # No signal:
    no_test.signal_connect "clicked" do
      noTest :view_in => in_view,
             :view_out => out_view,
             :yes => yes_test,
             :no => no_test,
             :stop => stop_test,
             :start => start_test
    end

    # Stop signal:
    stop_test.signal_connect "clicked" do
      stopTest :view_in => in_view,
               :view_out => out_view,
               :yes => yes_test,
               :no => no_test,
               :stop => stop_test,
               :start => start_test
   end


    # Add the grid:
    add grid

    # Finally, show everything and start!
    show_all
    Gtk.main
  end

  # Private method. Starts the test.
  private
  def startTest( opts = {} )
    # Don't do anything until there is some text to show:
    if opts[ :view_in ].buffer.text.empty?  then
      return
    end

    # Disable this button:
    opts[ :start ].sensitive = false

    # Get the kanjis from the given buffer:
    @kanjis = opts[ :view_in ].buffer.text.scan /./

    # Remove duplicates:
    @kanjis.uniq!

    # Remove useless characters:
    @kanjis.delete ""
    @kanjis.delete " "
    @kanjis.delete "\t"
    @kanjis.delete "\r"
    @kanjis.delete "\n"

    # Put in the first question:
    @question = @kanjis.sample
    opts[ :view_out ].buffer.text = "Conosci questo kanji? #{@question} " +
                                     "(Ne mancano: #{@kanjis.size})"

    # Enable the other buttons:
    opts[ :yes ].sensitive = true
    opts[ :no ].sensitive = true
    opts[ :stop ].sensitive = true
  end

  # Private method. Answer "yes" to the current question.
  private
  def yesTest( opts = {} )
    # If we know this knaji, gotta remove it from the list:
    @kanjis.delete @question

    # If the list is now empty, gotta stop:
    if @kanjis.empty? then
      opts[ :view_out ].buffer.text += " => OK!"
      stopTest :yes => opts[ :yes ],
               :no => opts[ :no ],
               :stop => opts[ :stop ],
               :start => opts[ :start ],
               :view_out => opts[ :view_out ],
               :finished => ""

    # Else, let's keep going!
    else
      # Get a new kanji to ask:
      @question = @kanjis.sample

      # Finally! Update the buffer:
      opts[ :view_out ].buffer.text += " => OK!\n" +
                                       "Conosci questo kanji? #{@question} " +
                                       "(Ne mancano: #{@kanjis.size})"
    end
  end

  # Private method. Answer "no" to the current question.
  private
  def noTest( opts = {} )

    # Show the correct answer, if we have one memorized:
    if @solutions.key? @question then
      # Kanji:
      message = "Kanji: #{@question}"

      # Meaning:
      if @solutions[ @question ].key? :ita then
        message += "\nSignificato: " +
                   "#{@solutions[ @question ][ :ita ].join ", "}"
      end

      # On:
      if @solutions[ @question ].key? :on then
        message += "\nOn: " +
                   "#{@solutions[ @question ][ :on ].join ", "}"
      end

      # Kun:
      if @solutions[ @question ].key? :kun then
        message += "\nKun: " +
                   "#{@solutions[ @question ][ :kun ].join ", "}"
      end

      # Show it:
      sol = Gtk::MessageDialog.new :parent => self, 
                                   :flags => :destroy_with_parent,
                                   :type => :info, 
                                   :buttons_type => :close,
                                   :message => message
      sol.run
      sol.destroy
    end

    # Well.. Then let's get a new kanji to ask:
    @question = @kanjis.sample

    # Register the fail, and move on:
    opts[ :view_out ].buffer.text += " => FAIL!\n" +
                                       "Conosci questo kanji? #{@question} " +
                                       "(Ne mancano: #{@kanjis.size})"
  end

  # Private method. Stops the test.
  private
  def stopTest( opts = {} )
    unless opts.key? :finished then
      opts[ :view_out ].buffer.text += " => STOP!"
    end

    # Just a little extra:
    opts[ :view_out ].buffer.text += "\n"

    # Enable the start button:
    opts[ :start ].sensitive = true

    # Disable the others:
    opts[ :yes ].sensitive = false
    opts[ :no ].sensitive = false
    opts[ :stop ].sensitive = false
  end

end

