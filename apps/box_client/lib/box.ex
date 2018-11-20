defmodule Box do
  def file(client, file_id, opts \\ []),
    do: Tesla.get(client, "/2.0/files/" <> file_id, query: opts)

  def file_download(client, file_id),
    do: Tesla.get(client, "/2.0/files/" <> file_id <> "/content")

  def file_expiring_embed(client, file_id),
    do: file(client, file_id, fields: "expiring_embed_link")

  def file_versions(client, file_id, opts \\ []),
    do: Tesla.get(client, "/2.0/files/" <> file_id <> "/versions", query: opts)

  def file_version(client, file_id, file_version_id),
    do: Tesla.get(client, "/2.0/files/" <> file_id <> "/versions/" <> file_version_id)

  def folder(client, folder_id, opts \\ []),
    do: Tesla.get(client, "/2.0/folders/" <> folder_id, query: opts)

  def folder_items(client, folder_id, opts \\ []),
    do: Tesla.get(client, "/2.0/folders/" <> folder_id <> "/items", query: opts)

  def create_folder(client, name, parent_id, opts \\ []),
    do:
      Tesla.post(
        client,
        "/2.0/folders",
        %{
          name: name,
          parent: %{
            id: parent_id
          }
        },
        query: opts
      )

  def update_folder(client, folder_id, name, description \\ nil, opts \\ []),
    do:
      Tesla.put(
        client,
        "/2.0/folders/" <> folder_id,
        %{
          name: name,
          description: description
        },
        query: opts
      )

  def delete_folder(client, folder_id, recursive \\ false),
    do:
      Tesla.delete(
        client,
        "/2.0/folders/" <> folder_id,
        recursive: recursive
      )

  def user(client, user_id \\ "me"), do: Tesla.get(client, "/2.0/users/" <> user_id)

  def users(client), do: Tesla.get(client, "/2.0/users")

  def search(client, query, opts \\ []),
    do: Tesla.get(client, "/2.0/search", query: [query: query] ++ opts)

  def client() do
    config = Application.get_env(:box_client, :box_app_settings)

    get_token_for_subject(config[:enterprise_id])
    |> process_token_response()
    |> Map.get("access_token")
    |> (fn token -> [token: token] end).()
    |> client()
  end

  def client(token: token) do
    middleware = [
      {Tesla.Middleware.BaseUrl, "https://api.box.com"},
      Tesla.Middleware.JSON,
      Tesla.Middleware.FollowRedirects,
      {Tesla.Middleware.Headers, [{"authorization", "Bearer " <> token}]}
    ]

    adapter = {Tesla.Adapter.Hackney, [recv_timeout: 30_000]}

    Tesla.client(middleware, adapter)
  end

  def client(user_id: user_id),
    do:
      get_token_for_subject(user_id, "user")
      |> process_token_response()
      |> Map.get("access_token")
      |> (fn token -> [token: token] end).()
      |> client()

  defp process_token_response({:ok, %Tesla.Env{status: 200, body: body}}),
    do:
      body
      |> Map.put("expires_at", body["expires_in"] + BoxClient.Util.unix_time_now())
      |> Map.delete("expires_in")

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

    adapter = {Tesla.Adapter.Hackney, [recv_timeout: 30_000]}

    client = Tesla.client(middleware, adapter)

    Tesla.post(client, "/oauth2/token", params)
  end
end
