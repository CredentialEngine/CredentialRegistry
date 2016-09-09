## Integration instructions and samples

### .NET

#### Generating the key pair

To generate a valid RSA key pair, we recommend using
[Git Bash for Windows](https://git-scm.com/downloads).

Once you have that installed, start a Git Bash session and run:

```bash
ssh-keygen -t rsa -b 4096 -f metadataregistry.key
ssh-keygen -f metadataregistry.key.pub -e -m pem > metadataregistry.key.pem
```

This will generate all your necessary key files.

#### Encoding the payload and generating a JWT token

Encoding the JSON payload isn't trivial in .NET due to poor framework support
for dealing with RSA key pairs. Fortunately, the
[BouncyCastle](https://www.bouncycastle.org/) suite fills in the blanks. JWT
support is given by [Jose](https://github.com/dvsekhvalnov/jose-jwt).

```csharp
RsaPrivateCrtKeyParameters privateKey;

using (var reader = File.OpenText(secretKeyPath))
{
    privateKey = (RsaPrivateCrtKeyParameters)((AsymmetricCipherKeyPair)new PemReader(reader).ReadObject()).Private;
}

string publicKey = File.ReadAllText(publicKeyPath);

string encoded = JWT.Encode(contents, DotNetUtilities.ToRSA(privateKey), JwsAlgorithm.RS256);
```

A full sample is available in [Envelope.cs](samples/dotnet/Envelope.cs).


### Lua

tested using Lua >= 5.1.5 and LuaJIT 2.0.4

```bash
luarocks install luacrypto
# 0.3.2-2
# If you are on mac OSX and installed openssl via homebrew, you might need to determine the OPENSSL_DIR. i.e:
# luarocks install luacrypto OPENSSL_DIR=/usr/local/opt/openssl

luarocks install jwt
# 0.5-2
```

```lua
  local cjson  = require 'cjson'
  local crypto = require 'crypto'
  local jwt    = require 'jwt'

  -- Read key from file
  local f = io.open("path/to/my/private_key", "rb")
  local key_content = f:read("*all")
  f:close()

  -- crypto pkey
  local pkey = crypto.pkey.from_pem(key_content, true)

  -- data
  local data = {
    something = "bla",
    test = true,
    num = 42,
  }

  -- encode token
  local token, _ = jwt.encode(data, {
    alg = "RS256",
    keys = { private = pkey }
  })

  print(token)
```

A full sample, with a runnable script, is available in [jwt_encode.lua](samples/lua/jwt_encode.lua).

```bash
lua jwt_encode.lua ~/path/to/my/json/content ~/path/to/my/private/key

luajit jwt_encode.lua ~/path/to/my/json/content ~/path/to/my/private/key
```


### Python

```bash
pip install pycrypto
pip install pyjwt
```

```python
import jwt
from jwt.contrib.algorithms.pycrypto import RSAAlgorithm

jwt.register_algorithm('RS256', RSAAlgorithm(RSAAlgorithm.SHA256))

with open('/path/to/private/key', 'r') as f:
  pkey = f.read()

data = {"test": True, "bla": "ble", "num": 42}

jwt.encode(data, pkey, algorithm='RS256')
```

A full sample, with a runnable script, is available in [jwt_encode.py](samples/python/jwt_encode.py).
