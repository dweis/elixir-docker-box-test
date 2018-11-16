defmodule BoxClient.Util do
  def unix_time_now(), do: DateTime.utc_now() |> DateTime.to_unix()

  def to_keyword_list(map) do
    Enum.map(map, fn {k, v} ->
      v =
        cond do
        is_map(v) -> to_keyword_list(v)
        is_list(v) -> Enum.map(v, &to_keyword_list(&1))
        true -> v
      end

      {String.to_atom("#{k}"), v}
    end)
  end
end
