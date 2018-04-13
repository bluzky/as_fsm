# Elixir Finite state machine

This package is inspired by [ecto_fsm](https://github.com/bluzky/ecto_fsm) package

This package allows to use [finite state machine pattern](https://en.wikipedia.org/wiki/Finite-state_machine) in elixir. 

## 1. Usage

Define your FSM

``` elixir
defmodule OrderState do

  # define state, event and transition 
  use EctoStateMachine,
    states: [:new, :processing, :cancelled, :delivered],
    events: [
      confirm: [
        name:     "Confirm",
        from:     [:new],
        to:       :processing,
        on_transition: fn(model, params) -> 
        # do something
        {:ok, model}
        end
      ], 
      deliver: [
        name:     "Deliver",
        from:     [:processing],
        to:       :delivered
      ], 
      cancel: [
        name:     "Cancel order",
        from:     [:new, :processing],
        to:       :cancelled,
        on_transition: &update_stock/2
      ]
    ]
    
    # define your callback function
    def update_stock(model, params)  do
      # your code
    end
end

```

**list all state** 
```elixir
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
#> model = %{status: :new}
#> OrderState.can?(model, :confirm)
#> true
#> OrderState.can?(model, :cancel)
#> true
#> OrderState.can?(model, :deliver)
#> false
```

**Get accepted events**
All events that can used to trigger a transition

```elixir
#> model = %{status: :new}
#> OrderState.accepted_events(model)
#> [{:confirm, "Confirm"}, {:cancel, "Cancel order"}]
```

**Trigger an event**

```elixir
#> model = %{status: :new}
#> OrderState.confirm(model)
#> %{status: :processing}
#> # you can even pass data when trigger event
#> OrderState.confirm(model, %{message: "oke man"})
```

**Dynamic trigger event**

```elixir
#> model = %{status: :new}
#> OrderState.trigger(model, :confirm)
#> %{status: :processing}
#> # you can even pass data when trigger event
#> OrderState.trigger(model, :confirm, %{message: "oke man"})
```

## Options

- Custom property name
```elixir
defmodule ExampleFsm do

  use AsFsm,
    column: :state,
end
```
