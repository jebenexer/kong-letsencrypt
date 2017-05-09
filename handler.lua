-- Copyright (C) Mashape, Inc.

local BasePlugin = require "kong.plugins.base_plugin"
local responses = require "kong.tools.responses"
local cache = require "kong.tools.database_cache"
local check_https = require("kong.tools.utils").check_https
local core = require "kong.core.handler"
local url = require "socket.url"
local singletons = require "kong.singletons"

function allowed_domains(domain)
  return domain:match('.*juiev.net$')
end

if not singletons.auto_ssl then
  auto_ssl = (require "resty.auto-ssl").new()
  auto_ssl:set("allow_domain", allowed_domains)
  auto_ssl:set("storage_adapter", "kong.plugins.letsencrypt.acme-storage")
  auto_ssl:init()
  singletons.auto_ssl = auto_ssl
else
  auto_ssl = singletons.auto_ssl
end


local cjson = require("cjson")

local LetsEncrypt = BasePlugin:extend()

LetsEncrypt.PRIORITY = 10000000

function LetsEncrypt:certificate()
  LetsEncrypt.super:certificate()
  auto_ssl:ssl_certificate()
end

function LetsEncrypt:_access()
  local uri  = url.parse(ngx.var.uri)
  local path = uri.path
  local well_known = '/.well-known/acme-challenge/'
  uri.scheme = "https"
  uri.host = ngx.var.host
  if not check_https(true) then
    if path:sub(1, well_known:len()) == well_known then
      ngx.ctx.is_challenge = true
    else
      ngx.header["connection"] = "Upgrade"
      ngx.header["upgrade"]    = "TLS/1.2, HTTP/1.1"
      ngx.header["Location"]   = url.build(uri)
      return responses.send(301, "Redirecting to HTTPS")
    end
  end
end

function LetsEncrypt:init_worker()
  auto_ssl:set("hook_server_port", singletons.configuration.admin_port)
  auto_ssl:init_worker()
end

function header_filter()
  if ngx.ctx.is_challenge then
    auto_ssl:challenge_server()
  end
end

function LetsEncrypt:new()
  self.super:new("letsencrypt")
  local original_ssl_certificate = kong.ssl_certificate
  function kong.ssl_certificate()
    core.certificate.before()
    LetsEncrypt:certificate()
  end

  local original_access = kong.access
  function kong.access()
    LetsEncrypt:_access()
    header_filter()
    original_access()
  end

  local original_header_filter = kong.header_filter
  function kong.header_filter()
    original_header_filter()
  end

  function kong.hook_server()
    auto_ssl:hook_server()
  end
end

return LetsEncrypt
