defmodule AsFsm do
  defmacro __using__(opts) do
    column = opts[:column] || :state

    quote do
      import AsFsm
      @column unquote(column)
      @states []
      @events %{}

      @before_compile AsFsm
    end
  end

  defmodule Event do
    defstruct key: nil, name: nil, from: [], to: nil, guard: nil
  end

  defmacro def_event(event_id, opts \\ []) do
    from = Keyword.get(opts, :from)
    to = Keyword.get(opts, :to)
    guard = Keyword.get(opts, :when)
    name = Keyword.get(opts, :name)
    name = Macro.expand(name, __CALLER__)

    if is_nil(from) do
      raise ArgumentError, message: ":from options is required"
    end

    if is_nil(to) do
      raise ArgumentError, message: ":to options is required"
    end

    from = if is_atom(from), do: [from], else: from

    quote do
      event = %Event{
        key: unquote(event_id),
        from: unquote(from),
        to: unquote(to),
        guard: unquote(guard),
        name: unquote(name)
      }

      @states [event.key | @states]
      @events Map.put(@events, event.key, event)
    end
  end

  @doc """
  guard function receiver 2 params, first is object, second params is additional params
  it should return
  :ok if success
  {:error, error_message} if failed
  """

  defmacro __before_compile__(_env) do
    quote do
      def states() do
        @states
      end

      def events() do
        Enum.map(@events, fn {key, event} -> {key, event.name} end)
        |> Enum.into(%{})
      end

      def can?(event_id, object, params \\ nil) do
        from = :"#{Map.get(object, @column)}"
        event = @events[event_id]

        with false <- is_nil(event),
             true <- from in event.from do
          if event.guard do
            apply(__MODULE__, event.guard, [object, params])
          else
            :ok
          end
        else
          true -> {:error, :event_undefined}
          _ -> {:error, :invalid_state}
        end
      end

      def available_events(object) do
        state = :"#{Map.get(object, @column)}"

        Enum.filter(@events, fn {_, event} -> state in event.from end)
        |> Enum.map(fn {key, event} ->
          {key, event.name}
        end)
        |> Enum.into(%{})
      end

      def trigger(event_id, object, args \\ nil) do
        event = @events[event_id]
        handler_name = :"on_#{event_id}"

        with false <- is_nil(event),
             true <- :erlang.function_exported(__MODULE__, handler_name, 2),
             :ok <- can?(event_id, object, args) do
          apply(__MODULE__, handler_name, [object, args])
        else
          true ->
            {:error, :event_undefined}

          false ->
            {:error, :handler_undefined}

          err ->
            err
        end
      end

      def blind_trigger(event_id, object, args \\ nil) do
        event = @events[event_id]
        handler_name = :"on_#{event_id}"

        with false <- is_nil(event),
             true <- :erlang.function_exported(__MODULE__, handler_name, 2) do
          apply(__MODULE__, handler_name, [object, args])
        else
          true ->
            {:error, :event_undefined}

          false ->
            {:error, :handler_undefined}

          err ->
            err
        end
      end

      def next_state(event_id) do
        event = @events[event_id]

        if event do
          event.to
        else
          :event_undefined
        end
      end
    end
  end
end
