require "test_helper"

class TaskTest < ActiveSupport::TestCase
  # ── Constants ────────────────────────────────────────────────────────────

  test "BATCH_LIMIT_FREE is 10" do
    assert_equal 10, Task::BATCH_LIMIT_FREE
  end

  test "BATCH_LIMIT_PRO is 30" do
    assert_equal 30, Task::BATCH_LIMIT_PRO
  end

  # ── batch_limit_for ───────────────────────────────────────────────────────

  test "batch_limit_for returns pro limit for subscribed user" do
    assert_equal 30, Task.batch_limit_for(users(:pro_user))
  end

  test "batch_limit_for returns free limit for unsubscribed user" do
    assert_equal 10, Task.batch_limit_for(users(:free_user))
  end

  test "batch_limit_for returns free limit for nil user" do
    assert_equal 10, Task.batch_limit_for(nil)
  end

  test "batch_limit_for returns free limit for expired subscription" do
    assert_equal 10, Task.batch_limit_for(users(:expired_user))
  end

  # ── associations ─────────────────────────────────────────────────────────

  test "has many uploads" do
    task = create_task
    create_upload(task: task)
    create_upload(task: task)
    assert_equal 2, task.uploads.count
  end
end
