require 'celluloid'

require 'qless'
require 'qless/job_reservers/ordered'
require 'qless/job_reservers/round_robin'

require 'qless/threaded_worker/util'

module Qless
  module ThreadedWorker
    ##
    # The Fetcher blocks on Redis, waiting for a message to process
    # from the queues.  It gets the message and hands it to the Manager
    # to assign to a ready Processor.
    class Fetcher
      include Celluloid
      include Qless::ThreadedWorker::Util

      TIMEOUT = 1

      def initialize(mgr)
        @mgr = mgr
        @client = Qless::Client.new
        
        queues = (ENV['QUEUES'] || ENV['QUEUE']).to_s.split(',').map { |q| @client.queues[q.strip] }
        if queues.none?
          raise "No queues provided. You must pass QUEUE or QUEUES when starting a worker."
        end

        @reserver = Qless::JobReservers.const_get(ENV.fetch('JOB_RESERVER', 'Ordered')).new(queues)
      end

      # Fetching is straightforward: the Manager makes a fetch
      # request for each idle processor when Sidekiq starts and
      # then issues a new fetch request every time a Processor
      # finishes a message.
      #
      # Because we have to shut down cleanly, we can't block
      # forever and we can't loop forever.  Instead we reschedule
      # a new fetch if the current fetch turned up nothing.
      def fetch
        watchdog('Fetcher#fetch died') do
          return if Fetcher.done?

          begin
            job = @reserver.reserve

            if job
              @mgr.async.assign(job)
            else
              after(0) { fetch }
            end
          rescue => ex
            log("Error fetching message: #{ex}")
            log(ex.backtrace.first)
            sleep(TIMEOUT)
            after(0) { fetch }
          end
        end
      end

      # Ugh.  Say hello to a bloody hack.
      # Can't find a clean way to get the fetcher to just stop processing
      # its mailbox when shutdown starts.
      def self.done!
        @done = true
      end

      def self.done?
        @done
      end
    end
  end
end

