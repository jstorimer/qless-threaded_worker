require 'minitest/autorun'
require 'rr'

require 'qless'

ENV['REDIS_URL'] = "redis://127.0.0.1:6379/11"
ENV['VVERBOSE'] = 'true'

# ghetto clear redis
`redis-cli -n 11 flushdb`

# Lifted from Qless test suite
class MiniTest::Unit::TestCase
  include RR::Adapters::TestUnit

  def with_env_vars(vars)
    original = ENV.to_hash
    vars.each { |k, v| ENV[k] = v }

    begin
      yield
    ensure
      ENV.replace(original)
    end
  end
end

class MyJob
  def self.perform(job)
    # shoop
  end
end

