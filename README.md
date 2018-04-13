# Elixir Finite state machine


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


You can check out whole `test/dummy` directory to inspect how to organize sample app.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add ecto_state_machine to your list of dependencies in `mix.exs`:

        def deps do
          [{:ecto_state_machine, "~> 0.1.0"}]
        end

### Custom column name

`ecto_state_machine` uses `state` database column by default. You can specify
`column` option to change it. Like this:

``` elixir
defmodule Dummy.User do
  use Dummy.Web, :model

  use EctoStateMachine,
    column: :rules,
    # bla-bla-bla
end
```

Now your state will be stored into `rules` column.

## Contributions

1. Install dependencies `mix deps.get`
1. Setup your `config/test.exs` & `config/dev.exs`
1. Run migrations `mix ecto.migrate` & `MIX_ENV=test mix ecto.migrate`
1. Develop new feature
1. Write new tests
1. Test it: `mix test`
1. Open new PR!

## Roadmap to 1.0

- [x] Cover by tests
- [x] Custom db column name
- [x] Validation method for changeset indicates its value in the correct range
- [x] Initial value
- [x] CI
- [x] Add status? methods
- [ ] Introduce it at elixir-radar and my blog
- [ ] Custom error messages for changeset (with translations by gettext ability)
- [x] Rely on last versions of ecto & elixir
- [ ] Write dedicated module instead of requiring everything into the model
- [ ] Write bang! methods which are raising exception instead of returning invalid changeset
- [ ] Rewrite spaghetti description in README
