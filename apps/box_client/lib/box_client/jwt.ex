defmodule BoxClient.Jwt do
  # https://developer.box.com/docs/construct-jwt-claim-manually#section-1-read-json-config
  defp get_key(private_key, passphrase) do
    key = private_key
    |> :public_key.pem_decode
    |> hd()
    |> :public_key.pem_entry_decode(passphrase)
    |> elem(3)

    :public_key.der_decode(:RSAPrivateKey, key)
  end
end
