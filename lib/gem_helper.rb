=begin
This class aims to easily install the gems required by this program (eg. gtk)
on different operating systems. Supports Linux, Windows but not Mac.
=end

class GemHelper

  # This method will detect the current operating system and install the
  # required gems accordingly.
  # Requires an array of gems to be given as a parameter.
  def self.fixGems( all_the_gems, at_all_costs = false )
    # Gems that are missing on the system:
    missing_gems = []

    # Attempt to require each gem. If such operation fails, then it should
    # be installed!
    all_the_gems.each do |entry|
      begin
        require "#{entry}"
      rescue LoadError
        missing_gems.push entry
      end
    end

    # If there are any missing gems, install them!
    unless missing_gems.empty? then
      # Should this go on until everything is done correctly? I don't know!
      # Not yet, at least.
      res = 0
      loop do
        puts "Will now install the missing gem(s): #{missing_gems.join ", "}",
             "Please wait..."

        # Depending on the OS:
        case RUBY_PLATFORM
          when /cygwin|mswin|mingw|bccwin|wince|emx/ then
            # On Windows, this workaround is needed:
            if missing_gems.include? "gtk3" then
              missing_gems[ missing_gems.index "gtk3" ] = "visualruby"
            end
            res = self.installOnWindows missing_gems 

          when /darwin/ then
            res = self.installOnMac missing_gems

          else
            res = self.installOnLinux missing_gems
        end

        puts "Result: #{res}"

        # Now i know if i should be quitting!
        break if false == at_all_costs or 0 == res

        # This is to make the output a little clearer:
        puts ""
      end
      puts "Done!"
    end

    # Be sure to reload gems:
    Gem.clear_paths
  end

  # Private method: installs the given gems on Linux.
  private
  def self.installOnLinux( gems )
    # Install the gems:
    `gem install --user-install #{gems.join " "}`

    # Return the exit status:
    return $?
  end

  # Private method: installs the given gems on Mac.
  private
  def self.installOnMac( gems )
    puts "Mac is not yet supported. Sorry."

    return 0
  end

  # Private method: installs the given gems on Windows.
  private
  def self.installOnWindows( gems )
    # Fix SSL certificate on Windows:
    ENV["SSL_CERT_FILE"] = "resources\\cacert.pem"

    # Finally, install the gems:
    `gem.cmd install #{gems.join " "}`

    # Return the exit status:
    return $?
  end

end

