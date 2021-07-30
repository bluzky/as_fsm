defmodule AsFsm do
  @moduledoc """
  Implement Finite state machine in elixir

  ## Usage

  **First you to define FSM module**
  ```elixir
  defmodule TaskFsm do
    use AsFsm, repo: MyApp.Repo
    # by default state is check from column `state` of struct
    # you can specify your own with
    # use AsFsm, repo: MyApp.Repo, column: :status

    # define your event
    defevent(:start, from: :idle, to: :running)
    defevent(:pause, from: :running, to: :paused)
    defevent(:stop, from: [:running, :paused], to: :idle)

    # you can define some hook
    # it is automatically invoked if defined

    def before_start(context) do
      # do something then return context
      context
    end

    def on_start(context) do
      # do something then return context
      context
    end
  end
  ```

  All appropriate event function will be generated. In this example we have
  ```elixir
  def start(context), do: ....
  def paus(context), do: ....
  def stop(context), do: ....
  ```

  **Then use it**
  - Trigger an even transition
  ```elixir
  my_task
  |> TaskFsm.new_context(other_params)
  |> TaskFsm.start()
  ```

  - Or trigger by name
  ```elixir
  my_task
  |> TaskFsm.new_context(other_params)
  |> TaskFsm.trigger(:start)
  ```

  ## Understand the context

  ```elixir
  @type :: %Context{
    struct: struct(),
    state: any(),
    valid?: boolean(),
    error: String.t() | nil,
    multi: Ecto.Multi.t() | nil
  }
  ```
  - `struct` is your data
  - `state` any data you want to pass to transition, it could be parameter from client
  - `valid?` if it is true, then data will be persisted
  - `error` error message in case `valid?` is false
  - `multi` is an `Ecto.Multi` you can pass a multi to `new_context()`, it make sure all action you do in a transaction

  ## Event hook
  For each event you can define 2 hook
  - `before_hook` you can define this hook to check for some condition before doing transation
  - `on_hook` this is your hook to do some logic on transaction

  These 2 hooks must return a context. If you want to stop this transition, set `valid?` to false and return the context.

  ## Custom persist struct
  You can define your own function to persist struct state. This function is run within Multi so that it must return `{:ok, data} | {:error, reason}`

  ```elixr
  def persist(struct, new_state, _context) do
    # do your update logic
    # or write log here
  end
  ```
  """

  defmodule Event do
    defstruct key: nil, name: nil, from: [], to: nil
  end

  defmodule Context do
    defstruct [:struct, :state, valid?: true, error: nil, multi: nil]

    def new(attr) when is_list(attr) do
      attr = Enum.reject(attr, fn {_k, v} -> is_nil(v) end)

      %Context{multi: Ecto.Multi.new()}
      |> struct(attr)
    end

    def new(struct) do
      %Context{struct: struct, multi: Ecto.Multi.new()}
    end
  end

  @type event :: %Event{
          key: atom(),
          name: String.t(),
          from: :atom | list(),
          to: :atom
        }

  @type context :: %Context{
          struct: struct(),
          state: any(),
          valid?: boolean(),
          error: String.t() | nil,
          multi: Ecto.Multi.t() | nil
        }

  defmacro __using__(opts) do
    column = opts[:column] || :state
    repo = opts[:repo] || raise "Repo is missing"

    quote location: :keep do
      import AsFsm

      @repo unquote(repo)

      @column unquote(column)
      Module.register_attribute(__MODULE__, :events, accumulate: true)
      @before_compile AsFsm

      def persist(struct, state, _context) do
        Ecto.Changeset.changeset(struct, [{@column, state}])
        |> @repo.update
      end

      defoverridable persist: 3
    end
  end

  defmacro defevent(event_id, opts \\ []) do
    from = Keyword.get(opts, :from)
    to = Keyword.get(opts, :to)
    name = Keyword.get(opts, :name)
    name = Macro.expand(name, __CALLER__)

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
        to: unquote(to),
        name: unquote(name)
      }

      def unquote(event_id)(context) do
        trigger(unquote(event_id), context)
      end
    end
  end

  @doc """
  List all events
  """
  @callback list_events() :: [event]

  @doc """
  List all available events for given state
  """
  @callback list_events(state :: atom()) :: [event]

  @doc """
  Get event object for given event name
  """
  @callback get_event(atom()) :: {:ok, event} | {:error, :event_undefined}

  @doc """
  Check if given event can be trigger with given state
  """
  @callback can(event_id :: atom(), current_state :: atom()) ::
              :ok | {:error, :event_undefined} | {:error, :invalid_state}

  @doc """
  Check if there is any transition from state_a to state_b
  """
  @callback has_transition?(from_state :: atom(), to_state :: atom()) :: boolean()

  @doc """
  Create new context
  ```elixir
  # new context without state data
  new_context(struct)

  # new context with data
  new_context(struct, params)

  # pass existing multi
  new_context(struct, params, existing_multi)
  ```
  """
  @callback new_context(struct(), state :: any(), multi :: Ecto.Multi.t()) :: context

  @doc """
  Trigger event by event name
  ```elixir
  MyFsm.new_context(my_order, %{user: user})
  |>  MyFsm.trigger(:deliver)
  ```
  """
  @callback trigger(context(), atom()) :: {:ok, map()} | {:error, map()}

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

      def new_context(struct, state \\ nil, multi \\ nil) do
        Context.new(struct: struct, state: state, multi: multi)
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
          persist(context.struct, to_state, context)
        end)
        |> @repo.transaction()
      end
    end
  end
end
