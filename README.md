# Elixir Finite state machine

This package is inspired by [ecto_fsm](https://github.com/bluzky/ecto_fsm) package

This package allows to use [finite state machine pattern](https://en.wikipedia.org/wiki/Finite-state_machine) in elixir. 


> I have rewritten this library to make code simple and easier to use
**Install**

```elixir
def deps do
  [
    {:as_fsm, "~> 2.0.0"}
  ]
end
```

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
  
## Options

- Custom property name by default property name is :state
```elixir
defmodule ExampleFsm do

  use AsFsm,
    column: :status,
end
```
