require 'celluloid'

require 'qless/threaded_worker/util'
require 'qless/threaded_worker/processor'
require 'qless/threaded_worker/fetcher'

module Qless
  module ThreadedWorker

    ##
    # The main router in the system.  This
    # manages the processor state and accepts messages
    # from Redis to be dispatched to an idle processor.
    #
    class Manager
      include Util
      include Celluloid

      trap_exit :processor_died

      def initialize(options={})
        log! options.inspect
        @count = ENV.fetch('CONCURRENCY', 25).to_i

        @in_progress = {}
        @done = false
        @busy = []
        @fetcher = Fetcher.new(current_actor)
        @ready = @count.times.map { Processor.new_link(current_actor) }
      end

      def stop(options={})
        watchdog('Manager#stop died') do
          shutdown = options[:shutdown]
          timeout = options[:timeout]

          @done = true
          Fetcher.done!
          @fetcher.async.terminate if @fetcher.alive?

          log "Shutting down #{@ready.size} quiet workers"
          @ready.each { |x| x.terminate if x.alive? }
          @ready.clear

          return after(0) { signal(:shutdown) } if @busy.empty?
          log "Pausing up to #{timeout} seconds to allow workers to finish..."
          hard_shutdown_in timeout if shutdown
        end
      end

      def start
        @ready.each { dispatch }
      end

      def processor_done(processor)
        watchdog('Manager#processor_done died') do
          @in_progress.delete(processor.object_id)
          @busy.delete(processor)
          if stopped?
            processor.terminate if processor.alive?
            signal(:shutdown) if @busy.empty?
          else
            @ready << processor if processor.alive?
          end
          dispatch
        end
      end

      def processor_died(processor, reason)
        watchdog("Manager#processor_died died") do
          @in_progress.delete(processor.object_id)
          @busy.delete(processor)

          unless stopped?
            @ready << Processor.new_link(current_actor)
            dispatch
          else
            signal(:shutdown) if @busy.empty?
          end
        end
      end

      def assign(job)
        watchdog("Manager#assign died") do
          if stopped?
            # Race condition between Manager#stop if Fetcher
            # is blocked on redis and reserves a job after
            # all the ready Processors have been stopped.
            # Push the job back to redis.
            job.retry
          else
            processor = @ready.pop
            @in_progress[processor.object_id] = job
            @busy << processor
            processor.async.process(job)
          end
        end
      end

      def procline(tag)
        "qless/threaded_worker #{Qless::ThreadedWorker::VERSION} #{tag}[#{@busy.size} of #{@count} busy]#{stopped? ? ' stopping' : ''}"
      end

      private

      def hard_shutdown_in(delay)
        after(delay) do
          watchdog("Manager#watch_for_shutdown died") do
            # We've reached the timeout and we still have busy workers.
            # They must die but their messages shall live on.
            log "Still waiting for #{@busy.size} busy workers"

            # Re-enqueue terminated jobs
            # Since the processor still isn't finished, and we have to shut
            # down, we can terminate the processor actor and retry the job.
            # This will put it back in the queue and clear its worker
            # association so another processor can pick it up when the system
            # comes back online.
            # NOTE: This might mean that at least part of a job gets run twice.
            # This is bad, I know. Process termination is delayed until we're 
            # certain the jobs are back in Redis because it is worse to lose 
            # a job than to run it twice.
            @in_progress.values.each(&:retry)

            log! "Terminating worker threads"
            @busy.each do |processor|
              processor.terminate if processor.alive?
            end

            after(0) { signal(:shutdown) }
          end
        end
      end

      def dispatch
        return if stopped?
        # This is a safety check to ensure we haven't leaked
        # processors somehow.
        raise "BUG: No processors, cannot continue!" if @ready.empty? && @busy.empty?
        raise "No ready processor!?" if @ready.empty?

        @fetcher.async.fetch
      end

      def stopped?
        @done
      end
    end
  end
end
