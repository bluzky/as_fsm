# Elixir Finite state machine

This package is inspired by [ecto_fsm](https://github.com/bluzky/ecto_fsm) package

This package allows to use [finite state machine pattern](https://en.wikipedia.org/wiki/Finite-state_machine) in elixir. 


> I have rewritten this library to make code simple and easier to use
**Install**

```elixir
def deps do
  [
    {:as_fsm, "~> 1.0.0"}
  ]
end
```

## 1. Usage

Define your FSM

``` elixir
defmodule TestFsm do
  use AsFsm

  def_event(:start, from: :idle, to: :running, name: "Start event", when: :check_it)
  def_event(:pause, from: :running, to: :paused, name: "Pause", when: :check_it)
  def_event(:stop, from: [:running, :paused], to: :idle, name: "Stop", when: :check_it)

  def check_it(object, params) do
    :ok
  end

  def on_start(object, params) do
    IO.inspect(object)
    IO.inspect(params)
    {:ok, object}
  end
end
```

**list all state** 
```shell
#> OrderState.states()
#> [:new, :processing, :cancelled, :delivered]
```

**list all event** 
```elixir
#> OrderState.events()
#> [{:confirm, "Confirm"}, {:deliver, "Deliver"}, {:cancel, "Cancel Order"}]
```

**Check if can accept event**
```elixir
#> model = %{state: :new}
#> OrderState.can?(:confirm, model)
#> true
#> OrderState.can?(:cancel, model)
#> true
#> OrderState.can?(:deliver, model)
#> false
```

**Get accepted events**
All events that can used to trigger a transition

```elixir
#> model = %{state: :new}
#> OrderState.available_events(model)
#> [{:confirm, "Confirm"}, {:cancel, "Cancel order"}]
```

**Trigger an event**

```elixir
#> model = %{state: :new}
#> OrderState.trigger(:confirm, model)
#> %{state: :processing}
#> # you can even pass data when trigger event
#> OrderState.trigger(:confirm, model, %{message: "oke man"})
```

## Options

- Custom property name by default property name is :state
```elixir
defmodule ExampleFsm do

  use AsFsm,
    column: :status,
end
```
