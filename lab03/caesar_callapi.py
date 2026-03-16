import sys
from PyQt5.QtWidgets import QApplication, QMainWindow, QMessageBox
from ui.caesar import Ui_MainWindow
import requests

class MyApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.ui = Ui_MainWindow()
        self.ui.setupUi(self)
        
        # Sửa lỗi: Đảm bảo có chữ 'r' trong btnEncrypt 
        # và khớp với btnDecrypt trong file UI của bạn
        self.ui.btnEncrypt.clicked.connect(self.call_api_encrypt)
        self.ui.btnDecrypt.clicked.connect(self.call_api_decrypt)

    def call_api_encrypt(self):
        url = "http://127.0.0.1:5000/api/caesar/encrypt"
        
        # Lấy dữ liệu từ các ô nhập liệu (khớp tên txtPlaintext, txtKey)
        payload = {
            "plain_text": self.ui.txtPlaintext.toPlainText(),
            "key": self.ui.txtKey.toPlainText()
        }
        
        try:
            response = requests.post(url, json=payload)
            if response.status_code == 200:
                data = response.json()
                # Hiển thị kết quả vào ô txtciphertext
                self.ui.txtciphertext.setPlainText(data["encrypted_message"])

                msg = QMessageBox()
                msg.setIcon(QMessageBox.Information)
                msg.setText("Encrypted Successfully")
                msg.setWindowTitle("Success")
                msg.exec_()
            else:
                print(f"Error while calling API: Status code {response.status_code}")
        except requests.exceptions.RequestException as e:
            print(f"Error: {e}")

    def call_api_decrypt(self):
        url = "http://127.0.0.1:5000/api/caesar/decrypt"
        
        # Lấy dữ liệu từ ô txtciphertext để giải mã
        payload = {
            "cipher_text": self.ui.txtciphertext.toPlainText(),
            "key": self.ui.txtKey.toPlainText()
        }
        
        try:
            response = requests.post(url, json=payload)
            if response.status_code == 200:
                data = response.json()
                # Hiển thị kết quả giải mã ngược lại ô txtPlaintext
                self.ui.txtPlaintext.setPlainText(data["decrypted_message"])

                msg = QMessageBox()
                msg.setIcon(QMessageBox.Information)
                msg.setText("Decrypted Successfully")
                msg.setWindowTitle("Success")
                msg.exec_()
            else:
                print(f"Error while calling API: Status code {response.status_code}")
        except requests.exceptions.RequestException as e:
            print(f"Error: {e}")

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = MyApp()
    window.show()
    sys.exit(app.exec_())