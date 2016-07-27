require_relative 'test_helper'

class IntegrationTest < Minitest::Test
  include ActiveJob::TestHelper

  def setup
    @redis = ActiveJobLock::Config.redis
    @redis.flushall
  end

  def test_jobs_same_args_running_in_parallel
    r1 = r2 = nil

    [
      Thread.new { r1 = SlowJob.perform_now(1) },
      Thread.new { sleep 0.01; r2 = SlowJob.perform_now(1) }
    ].map(&:join)

    assert_equal :performed, r1, 'First job should have been performed'
    assert_equal nil, r2, 'Second job should not have been performed because first job had the lock'
  end

  def test_jobs_diff_args_running_in_parallel
    r1 = r2 = nil

    [
      Thread.new { r1 = SlowJob.perform_now(1) },
      Thread.new { sleep 0.01; r2 = SlowJob.perform_now(2) }
    ].map(&:join)

    assert_equal :performed, r1, 'First job should have been performed'
    assert_equal :performed, r2, 'Second job should have been performed'
  end

  def test_jobs_same_args_running_in_parallel_with_timeout
    r1 = r2 = nil

    [
      Thread.new { r1 = SuperSlowWithTimeoutJob.perform_now(1) },
      Thread.new { sleep 2; r2 = SuperSlowWithTimeoutJob.perform_now(1) }
    ].map(&:join)

    assert_equal :performed, r1, 'First job should have been performed'
    assert_equal :performed, r2, 'Second job should have been performed because the timeout has passed'
  end

  def test_lock_releasing_with_failing_jobs
    FastJob.to_fail = true
    assert_raises { FastJob.perform_now(1) }
    FastJob.to_fail = false
    assert_equal :performed, FastJob.perform_now(1), 'Should have been performed assuming that the first job released the lock'
  end

  def test_loner_jobs
    LonerJob.perform_later
    assert_enqueued_jobs 1
    LonerJob.perform_later
    assert_enqueued_jobs 1
  end
end
