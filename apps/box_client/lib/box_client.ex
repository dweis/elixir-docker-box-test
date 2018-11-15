defmodule BoxClient do
  @moduledoc """
  A simple HTTP client for the Box API.
  """

  use HTTPoison.Base

  @endpoint "https://api.box.com"

  @expected_folder_fields ~w(
    type id sequence_id etag name created_at modified_at description size
    path_collection created_by modified_by trashed_at purged_at content_created_at
    content_modified_at expires_at owned_by shared_link folder_upload_email
    parent item_status item_collection sync_state has_collaborations permissions
    tags can_non_owners_invite is_externally_owned
    is_collaboration_restricted_to_enterprise allowed_shared_link_access_levels
    allowed_invitee_roles watermark_info metadata
  )

  @doc """
  Returns the folder for the given `token` and `folder_id`.
  """
  def get_folder(token, folder_id) do
    get("/2.0/folders/" <> folder_id, [make_auth(token)])
    |> process_json_result(@expected_folder_fields)
  end

  @expected_file_fields ~w(
    type id file_version sequence_id etag sha1 name description size path_collection
    created_at modified_at trashed_at purged_at content_created_at content_modified_at
    expires_at created_by modified_by owned_by shared_link parent item_status
    version_number comment_count permissions tags lock extension is_package
    expiring_embed_link watermark_info allow_invitee_roles is_externally_owned
    has_collaborations metadata
  )

  @doc """
  Returns the file for the given `token` and `file_id`
  """
  def get_file(token, file_id) do
    get("/2.0/files/" <> file_id, [make_auth(token)])
    |> process_json_result(@expected_file_fields)
  end

  @doc """
  Returns the binary content for the given `file_id`
  """
  def download_file(token, file_id) do
    get("/2.0/files/" <> file_id <> "/content", [make_auth(token)],
      hackney: [{:follow_redirect, true}]
    )
    |> process_download()
  end

  @expected_file_versions_fields ~w(total_count entries)

  @doc """
  Returns the file versions for the given `token` and `file_id`
  """
  def get_file_versions(token, file_id) do
    get("/2.0/files/" <> file_id <> "/versions", [make_auth(token)])
    |> process_json_result(@expected_file_versions_fields)
  end

  @expected_file_version_fields ~w(type ip sha1 name size created_at modified_at modified_by)

  @doc """
  Returns the file version for the given `token`, `file_id` and `file_version_id`
  """
  def get_file_version(token, file_id, file_version_id \\ "current") do
    get("/2.0/files/" <> file_id <> "/versions/" <> file_version_id, [make_auth(token)])
    |> process_json_result(@expected_file_version_fields)
  end

  @expected_user_fields ~w(
    type id name login created_at modified_at language timezone space_amount space_used
    max_upload_size status job_title phone address avatar_url role tracking_codes
    can_see_managed_users is_sync_enabled is_external_collab_restricted
    is_exempt_from_device_limits is_exempt_from_login_verification enterprise my_tags
    hostname is_platform_access_only
  )

  @doc """
  Returns the user data for the given `token` and `user_id`. `user_id` 
  can be "me" in which case the requesting user data will be returned.
  """
  def get_user(token, user_id \\ "me") do
    get("/2.0/users/" <> user_id, [make_auth(token)])
    |> process_json_result(@expected_user_fields)
  end

  @expected_token_fields ~w(access_token expires_in restricted_to token_type)

  def get_service_account_token do
    config = Application.get_env(:box_client, :box_app_settings)

    claims =
      BoxClient.Jwt.make_claims(
        config[:client_id],
        config[:public_key_id],
        config[:enterprise_id]
      )

    {:ok, assertion, _} = BoxClient.Jwt.sign_assertion(claims)

    params =
      URI.encode_query(%{
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: assertion,
        client_id: config[:client_id],
        client_secret: config[:client_secret]
      })

    post("/oauth2/token", params)
    |> process_json_result(@expected_token_fields)
  end

  @doc """
  Returns an absolute URL to the endpoint when given a relative `url`.

  ## Examples

     iex> BoxClient.process_url("/2.0/folders/0")
     "https://api.box.com/2.0/folders/0"
  """
  def process_url(url), do: @endpoint <> url

  defp process_json_result({:ok, response}, expected_fields) do
    case response.status_code do
      200 ->
        extract_fields_from_json(response.body, expected_fields)

      _ ->
        {:error, response}
    end
  end

  defp process_json_result({:error, response}, _expected_fields) do
    {:error, response}
  end

  defp process_download({:ok, response}) do
    case response.status_code do
      200 ->
        response.body

      _ ->
        {:error, response}
    end
  end

  defp process_download({:error, response}) do
    {:error, response}
  end

  defp extract_fields_from_json(json, expected_fields) do
    json
    |> Poison.decode!()
    |> Map.take(expected_fields)
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
  end

  defp make_auth(token) do
    {"authorization", "Bearer " <> token}
  end
end
