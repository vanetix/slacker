defmodule SlackerBackend.Message do
  defstruct [:user, :body, :sent_at]

  def new(attrs \\ []) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.to_iso8601()
    attrs =
      %{sent_at: now}
      |> Map.merge(attrs)

    struct(__MODULE__, attrs)
  end
end
