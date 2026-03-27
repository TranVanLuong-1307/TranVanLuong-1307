from flask import Flask, render_template, request, jsonify
from cipher.caesar import CaesarCipher
from cipher.vigenere import VigenereCipher
from cipher.railfence import RailfenceCipher
from cipher.playfair import PlayFairCipher
from cipher.transposition import TranspositionCipher
app = Flask(__name__)

@app.route("/")
def home():
    return render_template('index.html')

@app.route("/caesar")
def caesar():
    return render_template('caesar.html')

@app.route("/encrypt", methods=['POST'])
def caesar_encrypt():
    text = request.form['inputPlainText']
    key = int(request.form['inputKeyPlain'])
    
    caesar = CaesarCipher()
    encrypted_text = caesar.encrypt_text(text, key)
    return f"text: {text}<br/>key: {key}<br/>encrypted_text: {encrypted_text}"

@app.route("/decrypt", methods=['POST'])
def caesar_decrypt():
    text = request.form['inputCipherText']
    key = int(request.form['inputKeyCipher'])
    
    caesar = CaesarCipher()
    decrypted_text = caesar.decrypt_text(text, key)
    return f"text: {text}<br/>key: {key}<br/>decrypted_text: {decrypted_text}"

@app.route("/vigenere")
def vigenere():
    return render_template('vigenere.html')

@app.route("/vigenere_encrypt", methods=['POST'])
def vigenere_encrypt():
    text = request.form['text']
    key = request.form['key']
    
    v = VigenereCipher()
    encrypted_text = v.vigenere_encrypt(text, key)  # ← sửa tên method
    return f"text: {text}<br/>key: {key}<br/>encrypted_text: {encrypted_text}"

@app.route("/vigenere_decrypt", methods=['POST'])
def vigenere_decrypt():
    text = request.form['text']
    key = request.form['key']
    
    v = VigenereCipher()
    decrypted_text = v.vigenere_decrypt(text, key)  # ← sửa tên method
    return f"text: {text}<br/>key: {key}<br/>decrypted_text: {decrypted_text}"
@app.route("/railfence")
def railfence():
    return render_template('railfence.html')

@app.route("/railfence_encrypt", methods=['POST'])
def railfence_encrypt():
    text = request.form['text']
    key = int(request.form['key'])
    
    r = RailfenceCipher()
    encrypted_text = r.railfence_encrypt(text, key)  # ← sửa tên method
    return f"text: {text}<br/>key: {key}<br/>encrypted_text: {encrypted_text}"

@app.route("/railfence_decrypt", methods=['POST'])
def railfence_decrypt():
    text = request.form['text']
    key = int(request.form['key'])
    
    r = RailfenceCipher()
    decrypted_text = r.railfence_decrypt(text, key)  
    return f"text: {text}<br/>key: {key}<br/>decrypted_text: {decrypted_text}"

@app.route("/playfair")
def playfair():
    return render_template('playfair.html')

@app.route("/playfair_encrypt", methods=['POST'])
def playfair_encrypt():
    text = request.form['text']
    key = request.form['key']
    
    p = PlayFairCipher()
    matrix = p.create_playfair_matrix(key)
    encrypted_text = p.playfair_encrypt(text, matrix) 
    return f"text: {text}<br/>key: {key}<br/>encrypted_text: {encrypted_text}"

@app.route("/playfair_decrypt", methods=['POST'])
def playfair_decrypt():
    text = request.form['text']
    key = request.form['key']
    
    p = PlayFairCipher()
    matrix = p.create_playfair_matrix(key)
    decrypted_text = p.playfair_decrypt(text, matrix)  
    return f"text: {text}<br/>key: {key}<br/>decrypted_text: {decrypted_text}"
@app.route("/transposition")
def transposition():
    return render_template('transposition.html')
@app.route("/transposition_encrypt", methods=['POST'])
def transposition_encrypt():
    text = request.form['text']
    key = int(request.form['key'])  
    t = TranspositionCipher()
    encrypted_text = t.encrypt(text, key)
    return f"text: {text}<br/>key: {key}<br/>encrypted_text: {encrypted_text}"

@app.route("/transposition_decrypt", methods=['POST'])
def transposition_decrypt():
    text = request.form['text']
    key = int(request.form['key'])  
    
    t = TranspositionCipher()
    decrypted_text = t.decrypt(text, key)
    return f"text: {text}<br/>key: {key}<br/>decrypted_text: {decrypted_text}"
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5050, debug=True)