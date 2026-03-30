import sys
from PIL import Image

def decode_image(encoded_image_path):
    img = Image.open(encoded_image_path)
    width, height = img.size
    binary_message = ""
    
    # Duyệt qua từng pixel để trích xuất bit cuối cùng (LSB)
    for row in range(height):
        for col in range(width):
            pixel = img.getpixel((col, row))
            
            for color_channel in range(3): # Duyệt qua R, G, B
                # Lấy bit cuối cùng của giá trị màu và thêm vào chuỗi nhị phân
                binary_message += format(pixel[color_channel], '08b')[-1]
                
    message = ""
    # Chuyển đổi chuỗi nhị phân thành ký tự (mỗi 8 bit là 1 ký tự)
    for i in range(0, len(binary_message), 8):
        byte = binary_message[i:i+8]
        char = chr(int(byte, 2))
        
       
        if char == '\0': 
            break
        message += char
        
    return message

def main():
    if len(sys.argv) != 2:
        print("Usage: python decrypt.py <encoded_image_path>")
        return 
        
    encoded_image_path = sys.argv[1]
    decoded_message = decode_image(encoded_image_path)
    print("Decoded message:", decoded_message)
    
if __name__ == "__main__":
    main()