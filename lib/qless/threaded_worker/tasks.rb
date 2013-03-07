require 'qless/threaded_worker/manager'
require 'qless/threaded_worker/signal_overlord'

namespace :qless do
  namespace :threaded_worker do
    desc "Start a threaded Qless worker using env vars: CONCURRENCY, QUEUES, JOB_RESERVER, REDIS_URL, VERBOSE, VVERBOSE"
    task :work => :setup do
      require 'qless/threaded_worker/manager'

      manager = Qless::ThreadedWorker::Manager.new
      manager.async.start

      overlord = Qless::ThreadedWorker::SignalOverlord.new(manager)
      overlord.start # blocking call
    end
  end
end

