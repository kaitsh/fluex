defmodule Tester do
  use Fluex, otp_app: :fluex, resources: ["fluex.ftl"], requested: ["en", "it"]
end
