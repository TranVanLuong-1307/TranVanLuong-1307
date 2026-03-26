from cryptography.hazmat.primitives.asymmetric import dh
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes

def generate_client_key_pair(parameters):
    private_key = parameters.generate_private_key()
    public_key = private_key.public_key()
    return private_key, public_key

def derive_shared_secret(private_key, server_public_key):
    # Tính toán khóa bí mật chung từ private key của client và public key của server
    shared_key = private_key.exchange(server_public_key)
    return shared_key

def main():
    # 1. Load khóa công khai của server từ file
    with open("server_public_key.pem", "rb") as f:
        server_public_key = serialization.load_pem_public_key(f.read())

    # 2. Lấy tham số DH từ khóa công khai của server
    parameters = server_public_key.parameters()
    
    # 3. Tạo cặp khóa cho client dựa trên tham số đó
    private_key, public_key = generate_client_key_pair(parameters)

    # 4. Tính toán Shared Secret
    shared_secret = derive_shared_secret(private_key, server_public_key)

    # 5. In mã bí mật chung dưới dạng hex
    print("Shared Secret:", shared_secret.hex())

if __name__ == "__main__":
    main()