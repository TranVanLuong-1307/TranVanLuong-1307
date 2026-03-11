from flask import Flask, request, jsonify
from cipher.caesar import CaesarCipher 
from cipher.vigenere import VigenereCipher
from cipher.railfence import RailfenceCipher
from cipher.playfair import PlayFairCipher
from cipher.transposition import TranspositionCipher

app = Flask(__name__)
caesar_cipher = CaesarCipher()

@app.route("/api/caesar/encrypt", methods=["POST"])
def caesar_encrypt():
    data = request.json
    plain_text = data['plain_text']
    key = int(data['key'])
    encrypted_text = caesar_cipher.encrypt_text(plain_text, key)
    return jsonify({'encrypted_message': encrypted_text})

@app.route("/api/caesar/decrypt", methods=["POST"])
def caesar_decrypt():
    data = request.json
    cipher_text = data['cipher_text']
    key = int(data['key'])
    decrypted_text = caesar_cipher.decrypt_text(cipher_text, key)
    return jsonify({'decrypted_message': decrypted_text})

Vigenere_cipher = VigenereCipher()

@app.route("/api/vigenere/encrypt", methods=["POST"])
def vigenere_encrypt():
        data = request.json
        plain_text = data['plain_text']
        key = data['key']
        encrypted_text = Vigenere_cipher.vigenere_encrypt(plain_text, key)
        return jsonify({'encrypted_message': encrypted_text})
    
@app.route("/api/vigenere/decrypt", methods=["POST"])
def vigenere_decrypt():
        data = request.json
        cipher_text = data['plain_text']
        key = data['key']
        decrypted_text = Vigenere_cipher.vigenere_decrypt(cipher_text, key)
        return jsonify({'decrypted_message': decrypted_text})
    

Railfence_cipher = RailfenceCipher()

@app.route("/api/railfence/encrypt", methods=["POST"])
def railfence_encrypt():
    data = request.json
    plain_text = data['plain_text']
    key = int(data['key'])
    encrypted_text = Railfence_cipher.railfence_encrypt(plain_text, key)
    return jsonify({'encrypted_message': encrypted_text})

@app.route("/api/railfence/decrypt", methods=["POST"])
def railfence_decrypt():
    data = request.json
    cipher_text = data['cipher_text']
    key = int(data['key'])
    decrypted_text = Railfence_cipher.railfence_decrypt(cipher_text, key)
    return jsonify({'decrypted_message': decrypted_text})

Playfair_cipher = PlayFairCipher()
@app.route("/api/playfair/encrypt", methods=["POST"])
def playfair_create_matrix():
    data = request.json
    key = data['key']
    
    playfair_matrix = Playfair_cipher.create_playfair_matrix(key)
    return jsonify({'playfair_matrix': playfair_matrix})

@app.route("/api/playfair/decrypt", methods=["POST"])
def playfair_decrypt():
    data = request.json
    cipher_text = data['cipher_text']
    key = data['key']
    playfair_matrix = Playfair_cipher.create_playfair_matrix(key)
    decrypted_text = Playfair_cipher.decrypt(cipher_text, playfair_matrix)
    return jsonify({'decrypted_message': decrypted_text})

transposition_cipher = TranspositionCipher()
@app.route("/api/transposition/encrypt", methods=["POST"])
def transposition_encrypt():
    data = request.get_json
    plain_text = data.get('plain_text')
    key = int(data.get('key'))
    encrypted_text = transposition_cipher.encrypt(plain_text, key)
    return jsonify({'encrypted_message': encrypted_text})

@app.route("/api/transposition/decrypt", methods=["POST"])
def transposition_decrypt():
    data = request.get_json
    cipher_text = data.get('cipher_text')
    key = int(data.get('key'))
    decrypted_text = transposition_cipher.decrypt(cipher_text, key)
    return jsonify({'decrypted_message': decrypted_text})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
    

    