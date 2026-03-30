import sys
from PIL import Image

def encode_image(image_path, message):
    img = Image.open(image_path)
    width, height = img.size
    pixel_index = 0
    
    # Chuyển đổi thông điệp sang chuỗi nhị phân (8-bit cho mỗi ký tự)
    binary_message = ''.join(format(ord(char), '08b') for char in message)
    # Đánh dấu kết thúc thông điệp bằng chuỗi đặc biệt
    binary_message += '1111111111111110' 
    
    data_index = 0
    for row in range(height):
        for col in range(width):
            pixel = list(img.getpixel((col, row)))
            
            for color_channel in range(3): # Duyệt qua các kênh R, G, B
                if data_index < len(binary_message):
                    # Thay đổi bit cuối cùng (LSB) của kênh màu bằng bit của thông điệp
                    pixel[color_channel] = int(format(pixel[color_channel], '08b')[:-1] + binary_message[data_index], 2)
                    data_index += 1
            
            # Cập nhật lại điểm ảnh sau khi đã giấu tin
            img.putpixel((col, row), tuple(pixel))
            
            # Thoát vòng lặp nếu đã giấu xong toàn bộ thông điệp
            if data_index >= len(binary_message):
                break
        if data_index >= len(binary_message):
            break

    # Lưu ảnh đã được mã hóa
    encoded_image_path = 'encoded_image.png'
    img.save(encoded_image_path)
    print("Steganography complete. Encoded image saved as", encoded_image_path)

def main():
    if len(sys.argv) != 3:
        print("Usage: python encrypt.py <image_path> <message>")
        return

    image_path = sys.argv[1]
    message = sys.argv[2]
    encode_image(image_path, message)

if __name__ == "__main__":
    main()