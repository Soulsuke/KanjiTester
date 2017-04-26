require "pathname"
require "#{Pathname.new( $0 ).realpath.dirname}/lib/gem_helper.rb"

class KanjiTester

  # Entry point for the KanjiTester's launcher.
  # Takes ARGV as a parameter.
  def self.start( argv )
    # Max 2 command line parameters:
    if 2 > argv.size then

      # Check for supported flags:
      supported_args = [ "--check-only", "--help", "--no-check" ]
      if false == supported_args.include?( argv[ 0 ] ) and 
         false == argv.empty? then

        self.showHelp
        exit -1
      end

      # Help reference check:
      if "--help" == argv[ 0 ] then
        self.showHelp
        exit 0
      end

      # Run GemHelper only if:
      if "--check-only" == argv[ 0 ] or argv.empty? then
        # This array contains the required system gems:
        required_system_gems = [ "gtk3", "pathname", "yaml" ]

        puts "Starting GemHelper to check gem dependencies."
        puts "This may take a while, so be patient."
        puts ""

        # Be sure such gems are installed:
        GemHelper.fixGems required_system_gems

        puts "\nGemHelper exited."

        # If this was only a check, show a message and quit:
        if "--check-only" == argv[ 0 ] then
          puts "This terminal will automatically close in 20 seconds."
          sleep 20
        end
      end

      # Run KanjiHelper only if:
      if "--check-only" != argv[ 0 ] or argv.empty? then
        require "#{Pathname.new( $0 ).realpath.dirname}/lib/" +
                "kanji_tester_gui.rb"
        KanjiTesterGUI.new
      end

    else
      self.showHelp
      exit -1
    end
  end

  # Private method. Shows the help reference.
  private
  def self.showHelp
    help = Array.new
    help.push "KanjiHelper"
    help.push "Allowed switches:"
    help.push " --check-only.: only check if all the required gems are " +
              "installed"
    help.push " --help.......: show this help reference"
    help.push " --no-check...: run KanjiTester without checking for " +
              "available gems"

    puts help.join "\n"
  end

end

# If this file was used as the entry point, start away:
me = Pathname.new( $0 )
if "#{me.realpath}" == "#{me.realpath.dirname}/kanji_tester.rb" then
  KanjiTester.start ARGV
end

