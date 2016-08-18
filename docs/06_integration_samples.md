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
