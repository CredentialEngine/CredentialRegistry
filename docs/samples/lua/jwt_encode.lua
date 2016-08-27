-- Usage: lua jwt_encode.lua path/to/json/file.json path/to/private_key/pem

-- luarocks install luacrypto
-- luarocks install jwt
local cjson  = require 'cjson'
local crypto = require 'crypto'
local jwt    = require 'jwt'

-- read whole file into a string
function read_file(filepath)
    local f = io.open(filepath, "rb")
    local content = f:read("*all")
    f:close()
    return content
end

-- encode JWT passing the data table and the key path
function jwt_encode(data, key_path)
  local pkey = crypto.pkey.from_pem(read_file(key_path), true)
  local token, _ = jwt.encode(data, {
    alg = "RS256",
    keys = { private = pkey }
  })
  return token
end

-- get json data from file
local json_content = read_file(arg[1])
local data = cjson.decode(json_content)

-- get private key path
local key_path = arg[2]

-- encode our JWT token
local encoded_token = jwt_encode(data, key_path)

print(encoded_token)
