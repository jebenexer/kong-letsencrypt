-- daos.lua
local acme_challenge = {
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

return {acme_challenge = acme_challenge} -- this plugin only results in one custom DAO, named `keyauth_credentials`
