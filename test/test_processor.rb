require 'helper'
require 'qless/threaded_worker/processor'

describe Qless::ThreadedWorker::Processor do
  TestException = Class.new(StandardError)

  before do
    $invokes = 0
    @boss = Object.new
    @processor = Qless::ThreadedWorker::Processor.new(@boss)
    Celluloid.logger = nil
    #Sidekiq.redis = REDIS
    
    client = Qless::Client.new
    @queue = client.queues['default']
  end

  class BoomJob
    def self.perform(job)
      raise TestException if job.data['boom'] == true
      $invokes += 1
    end
  end

  def work(msg, queue='queue:default')
    Sidekiq::BasicFetch::UnitOfWork.new(queue, msg)
  end

  it 'processes as expected' do
    @queue.put(BoomJob, {})

    mgr = Object.new
    mock(mgr).processor_done(@processor)
    stub(@boss).async { mgr }

    job = @queue.pop
    @processor.process(job)

    assert_equal 1, $invokes
  end

  it 'retries on exceptions'
  it 'fails a non-retryable exception'
end

