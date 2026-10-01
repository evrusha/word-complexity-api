Rswag::Api.configure do
  it.openapi_root = Rails.root.join("docs/api").to_s
end

Rswag::Ui.configure do
  it.openapi_endpoint "/api-docs/openapi.yaml", "Word Complexity Score API"
end
