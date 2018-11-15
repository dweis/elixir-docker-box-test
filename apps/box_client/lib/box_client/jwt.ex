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

  def get_key(private_key, passphrase) do
    passphrase |> JOSE.JWK.from_pem(private_key)
  end

  def get_key_from_env() do
    get_key(System.get_env("SECRET_KEY"), System.get_env("SECRET_KEY_PASSPHRASE"))
  end

  def get_key_from_config_json(config_path \\ "config.json") do
    conf = parse_config_json(config_path)
    get_key(conf[:private_key], conf[:passphrase])
  end

  def get_issuer_from_config_json(config_path \\ "config.json") do
    conf = parse_config_json(config_path)
    conf[:client_id]
  end

  def parse_config_json(config_path) do
    config =
      File.read!(config_path)
      |> Poison.decode!()

    %{
      client_id: config["boxAppSettings"]["clientID"],
      client_secret: config["boxAppSettings"]["clientSecret"],
      public_key_id: config["boxAppSettings"]["appAuth"]["publicKeyID"],
      private_key: config["boxAppSettings"]["appAuth"]["privateKey"],
      passphrase: config["boxAppSettings"]["appAuth"]["passphrase"],
      enterprise_id: config["enterpriseID"]
    }
  end
end
