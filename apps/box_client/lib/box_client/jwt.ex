defmodule BoxClient.Jwt do
  @authentication_url "https://api.box.com/oauth2/token"

  # https://developer.box.com/docs/construct-jwt-claim-manually#section-1-read-json-config

  def make_claims(client_id, kid, sub, sub_type \\ "enterprise") do
    %{
      iss: client_id,
      sub: sub,
      box_sub_type: sub_type,
      aud: @authentication_url,
      kid: kid
    }
  end

  def sign_assertion(claims, ttl_seconds \\ 45) do
    BoxClient.Guardian.encode_and_sign(%{}, claims, ttl: {ttl_seconds, :seconds} )
  end

  def get_issuer do
    config = Application.get_env(:box_client, :box_app_settings)
    config[:client_id]
  end

  def get_key() do
    config = Application.get_env(:box_client, :box_app_settings)
    config[:passphrase] |> JOSE.JWK.from_pem(config[:private_key])
  end
end
