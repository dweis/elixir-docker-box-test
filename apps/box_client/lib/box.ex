defmodule Box do
  def file(client, file_id) do
    Tesla.get(client, "/2.0/files/" <> file_id)
  end

  def file_download(client, file_id) do
    Tesla.get(client, "/2.0/files/" <> file_id <> "/content")
  end

  def file_versions(client, file_id) do
    Tesla.get(client, "/2.0/files/" <> file_id <> "/versions")
  end

  def file_version(client, file_id, file_version_id) do
    Tesla.get(client, "/2.0/files/" <> file_id <> "/versions/" <> file_version_id)
  end

  def folder(client, folder_id) do
    Tesla.get(client, "/2.0/folders/" <> folder_id)
  end

  def folder_items(client, folder_id) do
    Tesla.get(client, "/2.0/folders/" <> folder_id <> "/items")
  end

  def user(client, user_id \\ "me") do
    Tesla.get(client, "/2.0/users/" <> user_id)
  end

  def users(client) do
    Tesla.get(client, "/2.0/users")
  end

  def search(token, query, opts \\ []) do
    Tesla.get(client, "/2.0/search", query: [query: query] ++ opts)
  end

  def client(token: token) do
    middleware = [
      {Tesla.Middleware.BaseUrl, "https://api.box.com"},
      Tesla.Middleware.JSON,
      Tesla.Middleware.FollowRedirects,
      {Tesla.Middleware.Headers, [{"authorization", "Bearer " <> token}]}
    ]

    Tesla.client(middleware)
  end

  def client() do
    config = Application.get_env(:box_client, :box_app_settings)
    get_token_for_subject(config[:enterprise_id])
    |> process_token_response()
    |> Map.get("access_token")
    |> (fn token -> [token: token] end).()
    |> client()
  end

  def client(user_id: user_id) do
    get_token_for_subject(user_id, "user")
    |> process_token_response()
    |> Map.get("access_token")
    |> (fn token -> [token: token] end).()
    |> client()
  end

  defp process_token_response({:ok, %Tesla.Env{status: 200, body: body}}) do
    body
    |> Map.put("expires_at", body["expires_in"] + BoxClient.Util.unix_time_now)
    |> Map.delete("expires_in")
  end

  defp get_token_for_subject(sub, sub_type \\ "enterprise") do
    config = Application.get_env(:box_client, :box_app_settings)

    params =
      URI.encode_query(%{
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: BoxClient.Jwt.make_assertion_for(sub, sub_type),
        client_id: config[:client_id],
        client_secret: config[:client_secret]
      })

    middleware = [
      {Tesla.Middleware.BaseUrl, "https://api.box.com"},
      Tesla.Middleware.JSON
    ]

    client = Tesla.client(middleware)

    Tesla.post(client, "/oauth2/token", params)
  end
end
