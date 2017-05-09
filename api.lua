local singletons = require "kong.singletons"

return {
  ["/deploy-challenge"] = {POST = function() singletons.auto_ssl:hook_server() end},
  ["/clean-challenge"] = {POST = function() singletons.auto_ssl:hook_server() end},
  ["/deploy-cert"] = {POST = function() singletons.auto_ssl:hook_server() end}
}
