using Jose;
using Newtonsoft.Json;
using Org.BouncyCastle.Crypto;
using Org.BouncyCastle.Crypto.Parameters;
using Org.BouncyCastle.OpenSsl;
using Org.BouncyCastle.Security;
using System.IO;

namespace MetadataRegistryExample
{
    public class Envelope
    {
        [JsonProperty(PropertyName = "envelope_type")]
        public string EnvelopeType { get; set; }

        [JsonProperty(PropertyName = "envelope_version")]
        public string EnvelopeVersion { get; set; }

        [JsonProperty(PropertyName = "envelope_community")]
        public string EnvelopeCommunity { get; set; }

        [JsonProperty(PropertyName = "resource")]
        public string Resource { get; set; }

        [JsonProperty(PropertyName = "resource_format")]
        public string ResourceFormat { get; set; }

        [JsonProperty(PropertyName = "resource_encoding")]
        public string ResourceEncoding { get; set; }

        [JsonProperty(PropertyName = "resource_public_key")]
        public string ResourcePublicKey { get; set; }

        /// <summary>
        /// Creates a MetadataRegistry envelope from an RSA key pair.
        /// </summary>
        /// <param name="publicKeyPath">Path to the public key file in the PEM format.</param>
        /// <param name="secretKeyPath">Path to the private key file in the PEM format.</param>
        /// <param name="contents">Envelope payload.</param>
        /// <returns>An Envelope that can be serialized and POST'ed to a MetadataRegistry server.</returns>
        public static Envelope CreateEnvelope(string publicKeyPath, string secretKeyPath, string contents)
        {
            RsaPrivateCrtKeyParameters privateKey;

            using (var reader = File.OpenText(secretKeyPath))
            {
                privateKey = (RsaPrivateCrtKeyParameters)((AsymmetricCipherKeyPair)new PemReader(reader).ReadObject()).Private;
            }

            string publicKey = File.ReadAllText(publicKeyPath);

            string encoded = JWT.Encode(contents, DotNetUtilities.ToRSA(privateKey), JwsAlgorithm.RS256);

            return new Envelope
            {
                EnvelopeType = "resource_data",
                EnvelopeVersion = "1.0.0",
                EnvelopeCommunity = "credential_registry",
                Resource = encoded,
                ResourceFormat = "json",
                ResourceEncoding = "jwt",
                ResourcePublicKey = publicKey
            };
        }
    }
}
