defmodule Fluex.FluentNIF do
  use Rustler, otp_app: :fluex, crate: :fluent_nif

  def new(_locale, _ftl), do: error()
  def has_message?(_bundle_ref, _id), do: error()
  def format_pattern(_bundle_ref, _id, _attrs), do: error()

  defp error, do: :erlang.nif_error(:nif_not_loaded)
end
