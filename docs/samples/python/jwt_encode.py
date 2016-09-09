import sys
import json
import jwt
from jwt.contrib.algorithms.pycrypto import RSAAlgorithm

jwt.register_algorithm('RS256', RSAAlgorithm(RSAAlgorithm.SHA256))

def read_file(path):
  with open(path, 'r') as f:
    content = f.read()
  return content

def jwt_encode(data, key_path):
  pkey = read_file(key_path)
  return jwt.encode(data, pkey, algorithm='RS256')

data = json.loads(read_file(sys.argv[1]))
key_path = sys.argv[2]

print(jwt_encode(data, key_path))
