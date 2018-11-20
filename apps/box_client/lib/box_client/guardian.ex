defmodule BoxClient.Guardian do
  use Guardian, otp_app: :box_client

  def subject_for_token(_resource, claims) do
    {:ok, claims["sub"]}
  end

  def resource_from_claims(_claims) do
    {:error, :reason_for_error}
  end
end
