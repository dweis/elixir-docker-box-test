defmodule BoxClient.Managed do
  def get_folder(folder_id \\ "0", opts \\ [])

  def get_folder(folder_id, user_id: user_id) do
    get_access_token(user_id)
    |> BoxClient.get_folder(folder_id)
  end

  def get_folder(folder_id, []) do
    get_access_token()
    |> BoxClient.get_folder(folder_id)
  end

  def get_access_token(user_id) do
    token = BoxClient.TokenStore.get(user_id)

    if token != nil and not expired?(token) do
      token
    else
      token = BoxClient.get_user_token(user_id)
      BoxClient.TokenStore.put(user_id, token)
      token
    end
  end

  def get_access_token() do
    token = BoxClient.TokenStore.get(:service_account)

    if token != nil and not expired?(token) do
      token
    else
      token = BoxClient.get_service_account_token()
      BoxClient.TokenStore.put(:service_account, token)
      token
    end
  end

  def expired?(token), do: token[:expires_at] < BoxClient.Util.unix_time_now()
end
