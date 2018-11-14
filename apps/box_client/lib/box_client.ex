defmodule BoxClient do
  use HTTPoison.Base

  @endpoint "https://api.box.com"

  def get_folder(token, folderId) do
    get("/2.0/folders/" <> folderId, [make_auth(token)])
  end

  def get_file(token, fileId) do
    get("/2.0/files/" <> fileId, [make_auth(token)])
  end

  defp process_url(url) do
    @endpoint <> url
  end

  defp process_response_body(body) do
    body
    |> Poison.decode!
    # |> Map.take ...
    # |> Enum.map(fn({k,v}) -> {String.to_atom(k), v} end)
  end

  defp make_auth(token) do
    {"authorization", "Bearer " <> token}
  end
end
