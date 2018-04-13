defmodule EctoStateMachineTest do
  use ExUnit.Case, async: true

  alias Dummy.OrderFsm

  setup_all do
    {
      :ok,
      new_order: %{status: :new},
      pending_order: %{status: :pending},
      cancelled_order: %{status: :cancelled},
      accepted_order: %{status: :accepted},
      delivering_order: %{status: :delivering},
      completed_order: %{status: :completed}
    }
  end

  describe "events" do
    test "list all states", context do
      assert length(OrderFsm.states()) == 6
    end

    test "list all events", context do
      events = OrderFsm.events()
      assert length(events) == 6
      assert List.first(events) == {:assign, "Assign"}
    end

    test "#assigns", context do
      data = context[:new_order]

      assert OrderFsm.can?(data, :assign) == true
      assert OrderFsm.can?(data, :accept) == false
      assert OrderFsm.can?(data, :reject) == false

      {status, data1} = OrderFsm.assign(data)
      assert status == :ok
      assert data1.status == :pending

      {status, _} = OrderFsm.reject(data)
      assert status == :error

      {status, _} = OrderFsm.reject(data)
      assert status == :error
    end

    test "trigger event by right name", context do
      data = context[:pending_order]

      {rc, cancelled_order} = OrderFsm.trigger(data, :reject)
      assert rc == :ok
      assert cancelled_order.status == :cancelled
    end

    test "trigger event by wrong name", context do
      data = context[:pending_order]

      {rc, _} = OrderFsm.trigger(data, :assign)
      assert rc == :error
    end

    test "trigger not exist event", context do
      data = context[:pending_order]

      {rc, _} = OrderFsm.trigger(data, :dum)
      assert rc == :error
    end

    test "get accepted event for current state", context do
      data = context[:pending_order]

      accepted_events = OrderFsm.accepted_events(data)

      assert length(accepted_events) == 2
      assert List.first(accepted_events) == {:accept, "Accept"}
    end
  end

  #   test "#block", context do
  #     changeset = User.block(context[:unconfirmed_user])
  #     assert changeset.valid? == false

  #     assert changeset.errors == [
  #              rules: {"You can't move state from :unconfirmed to :blocked", []}
  #            ]

  #     changeset = User.block(context[:confirmed_user])
  #     assert changeset.valid? == true
  #     assert changeset.changes.rules == "blocked"

  #     changeset = User.block(context[:blocked_user])
  #     assert changeset.valid? == false
  #     assert changeset.errors == [rules: {"You can't move state from :blocked to :blocked", []}]

  #     changeset = User.block(context[:admin])
  #     assert changeset.valid? == true
  #     assert changeset.changes.rules == "blocked"
  #   end

  #   test "#make_admin", context do
  #     changeset = User.make_admin(context[:unconfirmed_user])
  #     assert changeset.valid? == false
  #     assert changeset.errors == [rules: {"You can't move state from :unconfirmed to :admin", []}]

  #     changeset = User.make_admin(context[:confirmed_user])
  #     assert changeset.valid? == true
  #     assert changeset.changes.rules == "admin"

  #     changeset = User.make_admin(context[:blocked_user])
  #     assert changeset.valid? == false
  #     assert changeset.errors == [rules: {"You can't move state from :blocked to :admin", []}]

  #     changeset = User.make_admin(context[:admin])
  #     assert changeset.valid? == false
  #     assert changeset.errors == [rules: {"You can't move state from :admin to :admin", []}]
  #   end
  # end

  # describe "can_?" do
  #   test "#can_confirm?", context do
  #     assert User.can_confirm?(context[:unconfirmed_user]) == true
  #     assert User.can_confirm?(context[:confirmed_user]) == false
  #     assert User.can_confirm?(context[:blocked_user]) == false
  #     assert User.can_confirm?(context[:admin]) == false
  #   end

  #   test "#can_block?", context do
  #     assert User.can_block?(context[:unconfirmed_user]) == false
  #     assert User.can_block?(context[:confirmed_user]) == true
  #     assert User.can_block?(context[:blocked_user]) == false
  #     assert User.can_block?(context[:admin]) == true
  #   end

  #   test "#can_make_admin?", context do
  #     assert User.can_make_admin?(context[:unconfirmed_user]) == false
  #     assert User.can_make_admin?(context[:confirmed_user]) == true
  #     assert User.can_make_admin?(context[:blocked_user]) == false
  #     assert User.can_make_admin?(context[:admin]) == false
  #   end
  # end

  # test "#states" do
  #   assert User.rules_states() == [:unconfirmed, :confirmed, :blocked, :admin]
  # end

  # test "#events" do
  #   assert User.rules_events() == [:confirm, :block, :make_admin]
  # end
end
