require_relative 'helper'
require 'qless/threaded_worker/fetcher'

describe Qless::ThreadedWorker::Fetcher do
  before do
    # push a job
    client = Qless::Client.new
    @queue = client.queues['default']
    @queue.put(MyJob, :hello => 'howdy')
  end

  describe "a basic 'ordered reserver' fetch" do
    it "fetches a unit of work" do
      with_env_vars('QUEUES' => "default,top") do

        mgr = Object.new
        mock(mgr).assign(is_a(Qless::Job)) do |job|
          assert_equal MyJob, job.klass
          assert_equal 'default', job.queue.name

          job.perform
        end

        mgr_proxy = Object.new
        stub(mgr_proxy).async { mgr }

        fetcher = Qless::ThreadedWorker::Fetcher.new(mgr_proxy)
        job = fetcher.fetch
      end
    end
  end
end

