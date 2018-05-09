defmodule Dummy.OrderFsm do
  use AsFsm,
    column: :status,
    states: [:new, :pending, :accepted, :delivering, :closed, :cancelled],
    events: [
      assign: [
        name: "Assign",
        from: [:new],
        to: :pending,
        on_transition: &assign_user/2,
        on_enter: (fn(_, _) -> IO.inspect("Do something") end),
      ],
      accept: [
        name: "Accept",
        from: [:pending],
        to: :accepted
      ],
      reject: [
        name: "Reject",
        from: [:pending],
        to: :cancelled,
				guard: (fn(_, _) -> 
					IO.inspect("Doing guard") 
					true
				end)
      ],
      deliver: [
        name: "Deliver",
        from: [:accepted],
        to: :delivering
      ],
      reject: [
        name: "Cancel",
        from: [:delivering],
        to: :cancelled,
        on_transition: &return_product/2
      ],
      close: [
        name: "Close",
        from: [:delivering],
        to: :closed
      ]
    ]

  def assign_user(order, _params) do
    IO.inspect("assign order to some user")
    {:ok, order}
  end
	
	def enter_pending(_a, _b) do
		 IO.inspect("Order has been assigned to someone")
	end

  def return_product(order, _params) do
    IO.inspect("Return product to store")
    {:ok, order}
  end
end
