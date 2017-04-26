require "pathname"
require "#{Pathname.new( $0 ).realpath.dirname}/kanji_tester.rb"

=begin
Simple silent starter for Windows. Merely calls KanjiTester with the
"--no-check" flag.
=end

class KanjiTesterLauncherWindows
  # Simple silent start method.
  def self.start
    KanjiTester.start [ "--no-check" ]
  end
end

KanjiTesterLauncherWindows.start

