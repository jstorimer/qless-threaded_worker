
module Qless
  module ThreadedWorker
    ##
    # This module is part of Sidekiq core and not intended for extensions.
    #
    module Util
      def watchdog(last_words)
        yield
      rescue Exception => ex
        log last_words
        log ex
        log ex.backtrace.join("\n")
      end

      def log!(message)
        log message if ENV['VVERBOSE']
      end

      # Log a message to STDOUT if we are verbose or very_verbose.
      def log(message)
        if ENV['VERBOSE']
          output.puts "*** #{message}"
        elsif ENV['VVERBOSE']
          time = Time.now.strftime('%H:%M:%S %Y-%m-%d')
          output.puts "** [#{time}] #$$: #{message}"
        end
      end

      def output
        $stdout
      end

#      def redis(&block)
#        Sidekiq.redis(&block)
#      end
#
#      def process_id
#        Process.pid
#      end
#
#      def hostname
#        Socket.gethostname
#      end
    end
  end
end

