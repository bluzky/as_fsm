defmodule AsFsm do
  defmacro __using__(opts) do
    column = opts[:column] || :state

    quote location: :keep do
      import AsFsm

      @column unquote(column)
      Module.register_attribute(__MODULE__, :events, accumulate: true)
      @before_compile AsFsm

      def persist(_struct, state) do
        raise "Persist function is not implemented"
      end

      defoverridable persist: 2
    end
  end

  defmodule Event do
    defstruct key: nil, name: nil, from: [], to: nil
  end

  defmodule Context do
    defstruct [:struct, :state, valid?: true, error: nil, multi: nil]

    def new(struct) do
      %Context{struct: struct, multi: Ecto.Multi.new()}
    end

    def new(struct, state) do
      %Context{struct: struct, state: state, multi: Ecto.Multi.new()}
    end
  end

  defmacro defevent(event_id, opts \\ []) do
    from = Keyword.get(opts, :from)
    to = Keyword.get(opts, :to)
    # name = Keyword.get(opts, :name)
    # name = Macro.expand(name, __CALLER__)

    if is_nil(from) do
      raise ArgumentError, message: ":from options is required"
    end

    if is_nil(to) do
      raise ArgumentError, message: ":to options is required"
    end

    from = if is_atom(from), do: [from], else: from

    quote location: :keep do
      @events %Event{
        key: unquote(event_id),
        from: unquote(from),
        to: unquote(to)
      }

      def unquote(event_id)(context) do
        trigger(unquote(event_id), context)
      end
    end
  end

  @doc """
  guard function receiver 2 params, first is object, second params is additional params
  it should return
  :ok if success
  {:error, error_message} if failed
  """

  defmacro __before_compile__(_env) do
    quote location: :keep do
      def list_events() do
        Enum.map(@events, & &1.key)
      end

      def list_events(from_state) do
        Enum.filter(@events, &(from_state in &1.from))
        |> Enum.map(& &1.key)
      end

      def get_event(key) do
        event = Enum.find(@events, &(&1.key == key))

        if event do
          {:ok, event}
        else
          {:error, :event_undefined}
        end
      end

      def can(action, current_state) do
        event = Enum.find(@events, &(&1.key == action))

        with {:event, false} <- {:event, is_nil(event)},
             {:state, true} <- {:state, current_state in event.from} do
          :ok
        else
          {:event, _} -> {:error, :event_undefined}
          {:state, _} -> {:error, :invalid_state}
        end
      end

      def has_transition?(from_state, to_state) do
        Enum.find_value(@events, false, fn event ->
          from_state in event.from and to_state == event.to
        end)
      end

      def new_context(struct, state \\ nil) do
        Context.new(struct, state)
      end

      def trigger(%Context{} = context, event_id) do
        event = get_event(event_id)
        before_hook = :"before_#{event_id}"
        transition_hook = :"on_#{event_id}"

        with {:ok, event} <- get_event(event_id),
             {:ok, context} <- apply_hook(context, before_hook),
             {:ok, context} <- apply_hook(context, transition_hook) do
          final_multi(context, event.to)
        else
          err ->
            err
        end
      end

      defp apply_hook(context, hook_name) do
        if :erlang.function_exported(__MODULE__, hook_name, 1) do
          apply(__MODULE__, hook_name, [context])
        else
          {:ok, context}
        end
      end

      defp final_multi(%{valid?: true, multi: multi} = context, to_state) do
        Ecto.Multi.run(multi, :persist, fn _, _changes ->
          persist(context.struct, to_state)
        end)
        |> Repo.transaction()
      end
    end
  end
end
