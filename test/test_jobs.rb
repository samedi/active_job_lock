# Job that executes quickly
class FastJob < ActiveJob::Base
  include ActiveJobLock::Core

  class << self
    attr_accessor :to_fail
  end

  def perform(*_)
    raise if fail?
    :performed
  end

  def fail?
    self.class.to_fail
  end
end

# Slow successful job, does not use timeout algorithm.
class SlowJob < ActiveJob::Base
  include ActiveJobLock::Core

  def perform(*_)
    sleep 1
    return :performed
  end
end

# Job that enables the timeout algorithm.
class SuperSlowWithTimeoutJob < ActiveJob::Base
  include ActiveJobLock::Core

  lock timeout: 1

  def perform(*_)
    sleep 3
    return :performed
  end
end

# Job that can be enqueued one at a time
class LonerJob < ActiveJob::Base
  include ActiveJobLock::Core

  lock loner: true

  def perform(*_)
  end
end
