require 'qless/threaded_worker/version'

# Hack the default worker_name to include the current Thread id
# otherwise it won't be unique across worker threads
module Qless
  def worker_name
    preamble ||= [Socket.gethostname, Process.pid.to_s].join('-')
    [preamble, Thread.current.object_id].join('-')
  end
end

