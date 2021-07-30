defmodule Dummy.OrderFsm do
  use AsFsm, column: :status, repo: Repo

  defevent(:assign, from: :new, to: :pending)
  defevent(:accept, from: :pending, to: :accepted)
  defevent(:deliver, from: :accepted, to: :delivering)
  defevent(:reject, from: [:new, :pending, :accepted, :delivering], to: :cancelled)
  defevent(:complete, from: :delivering, to: :completed)

  def before_accept(%{struct: order} = context) do
    if order.quantity == 0 do
      {:error, %{context | valid?: false, errors: ["invalid quantity"]}}
    else
      {:ok, context}
    end
  end

  def on_accept(context) do
    IO.puts("Reduce stock")
    {:ok, context}
  end

  def persist(_order, _status, _) do
    {:ok, :succeeded}
  end
end
