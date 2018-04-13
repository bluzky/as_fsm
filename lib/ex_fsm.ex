defmodule AsFsm do
  @doc """
  """

  defmacro __using__(opts) do
    column = Keyword.get(opts, :column, :status)
    function_prefix = Keyword.get(opts, :prefix, "")
    sm_states = Keyword.get(opts, :states)

    events =
      Keyword.get(opts, :events)
      |> Enum.map(fn {event, transition} ->
        transition =
          Keyword.put_new(transition, :on_transition, quote(do: fn model, _ -> {:ok, model} end))

        {event, transition}
      end)
      |> Enum.map(fn {event, transition} ->
        transition = Keyword.update!(transition, :on_transition, &Macro.escape/1)
        {event, transition}
      end)

    quote bind_quoted: [
            sm_states: sm_states,
            events: events,
            column: column,
            function_prefix: function_prefix
          ] do
      def unquote(:"#{function_prefix}states")() do
        unquote(sm_states)
      end

      def unquote(:"#{function_prefix}events")() do
        unquote(events) |> Enum.map(fn {evt, transition} -> {evt, transition[:name]} end)
      end

      events
      |> Enum.each(fn {event, transition} ->
        unless transition[:to] in sm_states do
          raise "Target state :#{transition[:to]} is not present in ecto_state_machine definition states"
        end

        def unquote(event)(model), do: unquote(event)(model, %{})

        def unquote(event)(model, params) do
          if can?(model, unquote(event)) do
            case unquote(transition[:on_transition]).(model, params) do
              {:ok, model} ->
                {:ok, %{model | "#{unquote(column)}": unquote(transition[:to])}}

              err ->
                err
            end
          else
            {:error, "Current state does not accept event #{unquote(event)}"}
          end
        end

        def unquote(:"can_#{event}?")(model) do
          :"#{Map.get(model, unquote(column))}" in unquote(transition[:from])
        end
      end)

      def trigger(model, event, params \\ %{}) do
        event_names = unquote(Enum.map(events, &elem(&1, 0)))

        if event in event_names do
          apply(__MODULE__, event, [model, params])
        else
          raise "Event does not exist"
        end
      end

      def accepted_events(model) do
        current_state = Map.get(model, unquote(column), [])

        unquote(events)
        |> Enum.filter(fn {_, transition} -> current_state in transition[:from] end)
        |> Enum.map(fn {event, transition} -> {event, transition[:name]} end)
      end

      def can?(model, event) when is_atom(event) do
        current_state = Map.get(model, unquote(column), [])

        Enum.find_value(unquote(events), false, fn {evt_name, transition} = evt ->
          event == evt_name and current_state in transition[:from]
        end)
      end

      def can?(_, _), do: false
    end
  end
end
