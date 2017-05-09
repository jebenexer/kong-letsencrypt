local singletons = require "kong.singletons"

local challenge_dao = (require "kong.plugins.letsencrypt.daos").acme_challenge

local cert_dao = {}
local sni_dao = {}


local cjson = require "cjson"

local _M = {}

local function prefixed_key(self, key)
  if self.options["prefix"] then
    return self.options["prefix"] .. ":" .. key
  else
    return key
  end
end

function _M.new(auto_ssl_instance)
  return setmetatable({}, { __index = _M })
end

function _M.setup()
end

function _M.get(self, key)
  local domain, category, token = key:match("([^:]+):([^:]+):-([^:]-)$")

  local cert_dao = singletons.dao.ssl_certificates
  local sni_dao = singletons.dao.ssl_servers_names
  local challenge_dao = singletons.dao.acme_challenge


  if category == "latest" then
    local sni, err = sni_dao:find({ name = domain })

    if err then
      return nil, err
    end
    if sni then
      local cert, err = cert_dao:find { id = sni.ssl_certificate_id }
      cert_pem = cert.cert:match('(.*\\-\\-\\-\\-\\-END\\ CERTIFICATE\\-\\-\\-\\-\\-\\n)')
      return cjson.encode({
          fullchain_pem = cert.cert,
          privkey_pem = cert.key,
          cert_pem = cert_pem
      }), err
    else
      return nil, err
    end
  elseif category == "challenge" then
    challenge, err = challenge_dao:find {
      domain = domain,
      token = token
    }
    return challenge.payload, err
  end
end

function _M.set(self, key, value, options)
  local domain, category, token = key:match("([^:]+):([^:]+):-([^:]-)$")


  local cert_dao = singletons.dao.ssl_certificates
  local sni_dao = singletons.dao.ssl_servers_names
  local challenge_dao = singletons.dao.acme_challenge

  if category == "latest" then
    local sni, err = sni_dao:find { name = domain }
    if not sni then
      sni, err = sni_dao:insert { name = domain }
    end
    local data = cjson.decode(value)
    local cert, err = cert_dao:insert {
      cert = data['fullchain_pem'],
      key = data['privkey_pem']
    }
    if cert.id then
      sni.ssl_certificate_id = cert.id
      return sni_dao:update(sni, sni)
    end
  elseif category == "challenge" then
    local challenge, err = challenge_dao:find {
      domain = domain
    }
    if challenge then
      return challenge:update {
        token = token,
        payload = value
      }
    else
      return challenge_dao:insert {
        domain = domain,
        token = token,
        payload = value
      }
    end
  end
end

function _M.delete(self, key)
  local domain, category, token = key:match("([^:]+):([^:]+):-([^:]-)$")

  local cert_dao = singletons.dao.ssl_certificates
  local sni_dao = singletons.dao.ssl_servers_names
  local challenge_dao = singletons.dao.acme_challenge

  if category == "latest" then
    local sni, err = sni_dao:find { name = domain }
    return cert_dao:delete {
      id = sni.ssl_certificate_id
    }
  elseif category == "challenge" then
    return challenge_dao:delete {
      domain = domain
    }
  end
end

function _M.keys_with_suffix(self, suffix)
  local cert_dao = singletons.dao.ssl_certificates
  local sni_dao = singletons.dao.ssl_servers_names

  if suffix == ":latest" then
    local snis, err = sni_dao:find_all()
    local certs = {}
    for sni in snis do
      if sni.ssl_certificate_id then
        local cert, err = cert_dao:find {
          id = sni.ssl_certificate_id
        }
        if cert then
          certs:insert { name = ssl.name }
        end
      end
    end
    return certs
  end
end

return _M
