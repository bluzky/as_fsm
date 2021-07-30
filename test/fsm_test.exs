defmodule EctoStateMachineTest do
  use ExUnit.Case, async: true
  alias Dummy.OrderFsm

  describe "events" do
    test "list all events" do
      events = OrderFsm.list_events()
      assert length(events) == 5
      assert :assign in events
    end

    test "list event from existing state which have available event" do
      events = OrderFsm.list_events(:new)
      assert Enum.member?(events, :assign)
      assert Enum.member?(events, :reject)
    end

    test "list event from existing state which have no available event" do
      events = OrderFsm.list_events(:cancelled)
      assert events == []
    end

    test "list event from undefined state" do
      events = OrderFsm.list_events(:hello)
      assert events == []
    end

    test "get event with exising event" do
      assert {:ok, %{key: :assign}} = OrderFsm.get_event(:assign)
      assert {:ok, %{key: :accept}} = OrderFsm.get_event(:accept)
    end

    test "get event with undefined event" do
      assert {:error, :event_undefined} = OrderFsm.get_event(:hello)
    end

    test "check has event with current state" do
      assert OrderFsm.can(:accept, :pending) == :ok
    end

    test "check has event failed with no " do
      assert {:error, :invalid_state} = OrderFsm.can(:accept, :new)
    end

    test "check has event failed with undefined event" do
      assert {:error, :event_undefined} = OrderFsm.can(:hello, :new)
    end

    test "check has transaction between 2 event with transition" do
      assert OrderFsm.has_transition?(:new, :pending)
    end

    test "check has transaction between 2 event with no transition" do
      assert OrderFsm.has_transition?(:new, :accept) == false
    end
  end
end
