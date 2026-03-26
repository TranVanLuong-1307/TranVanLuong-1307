import sys
import socket
import threading
from PyQt5.QtWidgets import QApplication, QMainWindow
from PyQt5.QtCore import pyqtSignal
from client_ui import Ui_MainWindow

from Crypto.Cipher import AES, PKCS1_OAEP
from Crypto.PublicKey import RSA
from Crypto.Util.Padding import pad, unpad


class ClientApp(QMainWindow):
    message_signal = pyqtSignal(str)  # dùng để update UI an toàn

    def __init__(self):
        super().__init__()
        self.ui = Ui_MainWindow()
        self.ui.setupUi(self)

        self.client_socket = None
        self.aes_key = None

        # connect signal
        self.message_signal.connect(self.show_message)

        # Event
        self.ui.btnConnect.clicked.connect(self.connect_server)
        self.ui.btnSend.clicked.connect(self.send_message)

    def show_message(self, msg):
        self.ui.txtChat.append(msg)

    # 🔗 Kết nối server + trao đổi key
    def connect_server(self):
        try:
            self.client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.client_socket.connect(('localhost', 12345))

            self.client_key = RSA.generate(2048)

            server_public_key = RSA.import_key(self.client_socket.recv(2048))
            self.client_socket.send(self.client_key.publickey().export_key())

            encrypted_aes_key = self.client_socket.recv(2048)

            cipher_rsa = PKCS1_OAEP.new(self.client_key)
            self.aes_key = cipher_rsa.decrypt(encrypted_aes_key)

            self.show_message("✅ Connected & Key Exchange Done")

            threading.Thread(target=self.receive_messages, daemon=True).start()

        except Exception as e:
            self.show_message(f"❌ Error: {e}")

    # 🔐 AES encrypt
    def encrypt_message(self, message):
        cipher = AES.new(self.aes_key, AES.MODE_CBC)
        ciphertext = cipher.encrypt(pad(message.encode(), AES.block_size))
        return cipher.iv + ciphertext

    # 🔓 AES decrypt
    def decrypt_message(self, data):
        iv = data[:AES.block_size]
        ciphertext = data[AES.block_size:]
        cipher = AES.new(self.aes_key, AES.MODE_CBC, iv)
        return unpad(cipher.decrypt(ciphertext), AES.block_size).decode()

    # 📥 nhận đủ dữ liệu
    def recv_full(self):
        data = b''
        while True:
            packet = self.client_socket.recv(4096)
            if not packet:
                break
            data += packet
            if len(packet) < 4096:
                break
        return data

    # 📥 nhận tin
    def receive_messages(self):
        while True:
            try:
                data = self.recv_full()
                if not data:
                    break

                try:
                    message = self.decrypt_message(data)
                    self.message_signal.emit("Server: " + message)
                except Exception as e:
                    self.message_signal.emit(f"❌ Decrypt lỗi: {e}")

            except:
                break

    # 📤 gửi tin
    def send_message(self):
        if not self.client_socket:
            return

        message = self.ui.txtMessage.text()

        encrypted = self.encrypt_message(message)
        self.client_socket.send(encrypted)

        self.show_message("Me: " + message)

        # hiển thị AES/RSA
        self.ui.txtPlain.setText(message)
        self.ui.txtCipher.setText(str(encrypted))

        self.ui.txtMessage.clear()


if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = ClientApp()
    window.show()
    sys.exit(app.exec_())