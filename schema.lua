return {
  table = "acme_challenge",
  primary_key = { "domain" },
  fields = {
    domain = { type = "text", required = true, unique = true },
    token = { type = "text", required = true, unique = true },
    payload = { type = "text" },
    created_at = {
      type = "timestamp",
      immutable = true,
      dao_insert_value = true,
      required = true,
    },
  }
}
