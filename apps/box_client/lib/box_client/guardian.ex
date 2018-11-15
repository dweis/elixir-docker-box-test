defmodule BoxClient.Guardian do
  use Guardian, otp_app: :box_client

  def subject_for_token(resource, claims) do
    {:ok, claims["sub"]}
  end

  def subject_for_token(_, _) do
    {:error, :reason_for_error}
  end
end
