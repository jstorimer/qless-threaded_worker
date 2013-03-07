# Qless::ThreadedWorker

This gem provides an alternative worker model for Qless. Qless currently implements a worker inspired by Resque (one process per worker), this gem adds an implementation inspired by Sidekiq (one thread per worker).

We attempt to preserve behaviour wrt to signals and regular Qless behaviour where possible. These are the areas that we fail to do so:

1. Since the 'middleware chain' is just implemented as series of includes on a class, rather than a real set of objects, you'll have to make sure you include your middlewares on our worker class, rather than the core one.

  class Qless::ThreadedWorker::Processor
    include Middleware::Foo
  end

2. 

## Installation

Add this line to your application's Gemfile:

    gem 'qless-threaded_worker'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install qless-threaded_worker

## Usage

Qless ships with some rake tasks for their process-based worker. Simply use the rake tasks provided by this gem in their place to spin up a threaded worker.

``` ruby
require 'qless/threaded_worker_tasks'

namespace :qless do
  task :setup do
    require 'my_app/environment' # to ensure all job classes are loaded

    # Set options via environment variables
    # The only required option is QUEUES; the
    # rest have reasonable defaults.
    ENV['REDIS_URL'] ||= 'redis://some-host:7000/3'
    ENV['QUEUES'] ||= 'fizz,buzz'
    ENV['JOB_RESERVER'] ||= 'Ordered'
    ENV['INTERVAL'] ||= '10' # 10 seconds
    ENV['VERBOSE'] ||= 'true'
  end
end
```

Then run the `qless:work` rake task:

    rake qless:threaded_worker

## Dependencies

Celluloid

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
