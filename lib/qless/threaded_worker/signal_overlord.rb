require 'qless/threaded_worker/util'

module Qless
  module ThreadedWorker
    class SignalOverlord
      include Util
      # The Overlord never exits. It just sleeps until
      # a signal arrives, then wakes up, handles it, goes
      # back to sleep.
      #
      # The following signals are supported by Qless proper:
      # 
      #   * TERM: Shutdown immediately, stop processing jobs.
      #   *  INT: Shutdown immediately, stop processing jobs.
      #   * QUIT: Shutdown after the current job has finished processing.
      #   * USR1: Kill the forked child immediately, continue processing jobs.
      #   * USR2: Don't process any new jobs
      #   * CONT: Start processing jobs again after a USR2

      # We can't do USR1 because there's only one process.
      # Until I have a use case for pause/unpause, I'll ignore.
      #
      # So we'll do
      #
      #   * TERM: Force shutdown immediately, stop processing jobs.
      #   *  INT: Force shutdown immediately, stop processing jobs.
      #   * QUIT: Graceful shutdown, shutdown after the current job has finished processing.

      QLESS_SIGNALS = []
      SUPPORTED_SIGNALS = [:TERM, :INT, :QUIT]
      DEFAULT_SHUTDOWN_TIMEOUT = 8

      def initialize(manager)
        # This is the self-pipe the overlord uses to
        # manage its state. It goes to sleep by select()ing
        # on the read end of the pipe. When a signal arrives,
        # it writes to the write end of the pipe to wake
        # the sleeping overlord.
        @read_pipe, @write_pipe = IO.pipe

        @manager = manager
        trap_signals
      end

      def start
        loop do
          @read_pipe.read(1)
          handle_signal
        end
      end

      private
      def trap_signals
        SUPPORTED_SIGNALS.each do |sig|
          trap(sig) do
            # do as little as possible within a signal
            # handler. Just put the signal we received
            # into a list and wake the sleeping overlord.
            QLESS_SIGNALS << sig
            log! "Received #{sig}..."
            wake_up
          end
        end
      end

      def wake_up
        log! 'Waking up overlord'
        @write_pipe.write_nonblock('.')
      end

      def handle_signal
        case QLESS_SIGNALS.shift
        when :TERM, :INT
          log 'Going for hard shutdown...'
          hard_shutdown
          exit
        when :QUIT
          log 'Going for graceful shutdown...'
          graceful_shutdown
          exit
        end
      end

      def hard_shutdown
        @manager.stop(:shutdown => true, :timeout => DEFAULT_SHUTDOWN_TIMEOUT)
      end

      def graceful_shutdown
        @manager.stop(:shutdown => false, :timeout => DEFAULT_SHUTDOWN_TIMEOUT)
      end
    end
  end
end

