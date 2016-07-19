ActiveJob Lock
===================

An [ActiveJob][activejob] plugin.

active_job_lock adds locking, with optional timeout/deadlock handling.

Using a `lock_timeout` allows you to re-acquire the lock should your job
fail, crash, or is otherwise unable to release the lock. **i.e.** Your server
unexpectedly loses power. Very handy for jobs that are recurring or may be
retried.

**n.b.** By default, a job that fails to acquire a lock will be dropped. You can handle lock failures by implementing the available [callback](#callbacks).

Usage / Examples
----------------

### Single Job Instance

    class UpdateNetworkGraph < ActiveJob::Base
      include ActiveJobLock::Core

      queue_as :network_graph

      def perform(repo_id)
        heavy_lifting
      end
    end

Locking is achieved by storing a identifier/lock key in Redis.

Default behavior...

* Only one instance of a job may execute at once.
* The lock is held until the job completes or fails.
* If another job is executing with the same arguments the job will abort.

Please see below for more information about the identifier/lock key.

### Enqueued Exclusivity (Loner Option)

Setting the `@loner` boolean to `true` will ensure the job is not enqueued if
the job (identified by the `identifier` method) is already running/enqueued.

    class LonelyJob < ActiveJob::Base
      include ActiveJobLock::Core

      queue_as :loners
      lock loner: true

      def perform(repo_id)
        heavy_lifting
      end
    end

### Lock Expiry/Timeout

The locking algorithm used can be found in the [Redis SETNX][redis-setnx]
documentation.

Simply set the lock timeout in seconds, e.g.

    class UpdateNetworkGraph < ActiveJob::Base
      include ActiveJobLock::Core

      queue_as :network_graph
      # Lock may be held for up to an hour.
      lock timeout: 3600

      def perform(repo_id)
        heavy_lifting
      end
    end

Customize & Extend
==================

### Job Identifier/Lock Key

By default the key uses this format: `lock:<job class name>:<identifier>`.

The default identifier is just your job arguments joined with a dash `-`.

If you have a lot of arguments or really long ones, you should consider
overriding `identifier` to define a more precise or loose custom identifier:

    class UpdateNetworkGraph < ActiveJob::Base
      include ActiveJobLock::Core

      queue_as :network_graph

      # Run only one at a time, regardless of repo_id.
      def identifier(repo_id)
        nil
      end

      def perform(repo_id)
        heavy_lifting
      end
    end

The above modification will ensure only one job of class
UpdateNetworkGraph is running at a time, regardless of the
repo_id.

Its lock key would be: `lock:UpdateNetworkGraph` (the `:<identifier>` part is left out if the identifier is `nil`).

You can define the entire key by overriding `redis_lock_key`:

    class UpdateNetworkGraph < ActiveJob::Base
      include ActiveJobLock::Core

      queue_as :network_graph

      def redis_lock_key(repo_id)
        "lock:updates"
      end

      def perform(repo_id)
        heavy_lifting
      end
    end

That would use the key `lock:updates`.

### Redis Connection Used for Locking

By default all locks are stored via a Redis client. For that, you have to tell `ActiveJobLock`
which client it should use. Set that through an initializer:

    # config/initializers/active_job_lock.rb

    ActiveJobLock::Config.redis = Redis.new(redis_config)

If you want, you can then override it per job instance by doing:

    class UpdateNetworkGraph < ActiveJob::Base
      include ActiveJobLock::Core

      queue_as :network_graph

      def lock_redis
        @lock_redis ||= CustomRedis.new
      end

      def perform(repo_id)
        heavy_lifting
      end
    end

### Setting Timeout At Runtime

You may define the `lock_timeout` method to adjust the timeout at runtime
using job arguments. e.g.

    class UpdateNetworkGraph < ActiveJob::Base
      include ActiveJobLock::Core

      queue_as :network_graph

      def lock_timeout(repo_id, timeout_minutes)
        60 * timeout_minutes
      end

      def perform(repo_id, timeout_minutes = 1)
        heavy_lifting
      end
    end

### Helper Methods

* `locked?` - checks if the lock is currently held.
* `enqueued?` - checks if the loner lock is currently held.
* `loner_locked?` - checks if the job is either enqueued (if a loner) or locked (any job).
* `refresh_lock!` - Refresh the lock, useful for jobs that are taking longer
    then usual but your okay with them holding on to the lock a little longer.

### <a name="callbacks"></a> Callbacks

Several callbacks are available to override and implement your own logic, e.g.

    class UpdateNetworkGraph < ActiveJob::Base
      include ActiveJobLock::Core

      queue_as :network_graph
      lock timeout: 3600, loner: true

      # Job failed to acquire lock. You may implement retry or other logic.
      def lock_failed(repo_id)
        raise LockFailed
      end

      # Unable to enqueue job because its running or already enqueued.
      def loner_enqueue_failed(repo_id)
        raise EnqueueFailed
      end

      # Job has complete; but the lock expired before we could release it.
      # The lock wasn't released; as its *possible* the lock is now held
      # by another job.
      def lock_expired_before_release(repo_id)
        handle_if_needed
      end

      def perform(repo_id)
        heavy_lifting
      end
    end

Install
=======

    $ gem install active_job_lock

Acknowledgements
================

Forked and adapted from Luke Antins' [resque-lock-timeout v0.4.5][resque-lock-timeout] plugin.

[activejob]: https://github.com/rails/rails/tree/master/activejob
[resque-lock-timeout]: https://github.com/lantins/resque-lock-timeout/tree/v0.4.5
[redis-setnx]: http://redis.io/commands/setnx
