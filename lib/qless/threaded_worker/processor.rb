require 'celluloid'
require 'qless/threaded_worker/util'

module Qless
  module ThreadedWorker
    ##
    # The Processor receives a message from the Manager and actually
    # processes it.  It calls Job#perform and runs the middleware
    # chain.
    class Processor
      include Util
      include Celluloid

      def initialize(boss)
        @boss = boss
      end

      def process(job)
        defer do
          perform(job)
        end
        @boss.async.processor_done(current_actor)
      end

      # Lifted right from Qless::Worker
      def perform(job)
        around_perform(job)
      rescue *retryable_exception_classes(job)
        job.retry
      rescue Exception => error
        fail_job(job, error)
      else
        try_complete(job)
      end

      def to_s
        @str ||= "#{Socket.gethostname}:#{Process.pid}-#{Thread.current.object_id}:default"
      end
      
      # See http://github.com/tarcieri/celluloid/issues/22
      def inspect
        "#<Processor #{to_s}>"
      end

      private

      def retryable_exception_classes(job)
        return [] unless job.klass.respond_to?(:retryable_exception_classes)
        job.klass.retryable_exception_classes
      rescue NameError => exn
        []
      end

      def try_complete(job)
        job.complete unless job.state_changed?
      rescue Job::CantCompleteError => e
        # There's not much we can do here. Complete fails in a few cases:
        #   - The job is already failed (i.e. by another worker)
        #   - The job is being worked on by another worker
        #   - The job has been cancelled
        #
        # We don't want to (or are able to) fail the job with this error in
        # any of these cases, so the best we can do is log the failure.
        log "Failed to complete #{job.inspect}: #{e.message}"
      end

      # Allow middleware modules to be mixed in and override the
      # definition of around_perform while providing a default
      # implementation so our code can assume the method is present.
      include Module.new {
        def around_perform(job)
          job.perform
        end
      }

      def fail_job(job, error)
        group = "#{job.klass_name}:#{error.class}"
        message = "#{error.message}\n\n#{error.backtrace.join("\n")}"
        log "Got #{group} failure from #{job.inspect}"
        job.fail(group, message)
      end
    end
  end
end

