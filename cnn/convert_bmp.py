import os
from PIL import Image

def create_image_rom():
    # --- 설정 ---
    image_filename = 'train_4.bmp'  # 처리할 이미지 이름
    image_folder = os.path.join('mnist_cnn', 'bmp')
    output_verilog_file = 'image_rom4.v'
    
    IMG_WIDTH, IMG_HEIGHT = 28, 28
    image_path = os.path.join(image_folder, image_filename)
    
    if not os.path.exists(image_path):
        print(f"Error: 파일을 찾을 수 없습니다 {image_path}")
        return

    try:
        with Image.open(image_path) as img:
            gray_img = img.convert('L') # 그레이스케일 변환
            if gray_img.size != (IMG_WIDTH, IMG_HEIGHT):
                gray_img = gray_img.resize((IMG_WIDTH, IMG_HEIGHT))
            
            pixel_data = list(gray_img.getdata())
    except Exception as e:
        print(f"에러 발생: {e}")
        return

    # --- Verilog ROM 생성 시작 ---
    verilog_code = []
    verilog_code.append("`timescale 1ns / 1ps\n")
    verilog_code.append(f"// Generated from: {image_filename} (Scaled by 127)")
    verilog_code.append("module image_rom (")
    verilog_code.append("    input wire [9:0] addr,")
    verilog_code.append("    output reg [7:0] dout")
    verilog_code.append(");\n")
    verilog_code.append("    always @(*) begin")
    verilog_code.append("        case(addr)")
    
    for i, pixel_value in enumerate(pixel_data):
        # ---------------------------------------------------------
        # [핵심 수정 부분] 
        # 0~255인 픽셀 값을 0~1로 정규화한 뒤, 
        # 가중치와 똑같이 127을 곱해서 8비트 정수로 만듭니다.
        # ---------------------------------------------------------
        scaled_pixel = int(round((pixel_value / 255.0) * 127))
        
        # 16진수 2자리로 변환
        hex_pixel = format(scaled_pixel & 0xFF, '02x')
        verilog_code.append(f"            10'd{i}: dout = 8'h{hex_pixel};")
        
    verilog_code.append("            default: dout = 8'h00;")
    verilog_code.append("        endcase")
    verilog_code.append("    end\n")
    verilog_code.append("endmodule")

    with open(output_verilog_file, 'w') as f:
        f.write('\n'.join(verilog_code))
    
    print(f"성공: {output_verilog_file} 생성 완료 (양자화 적용됨)")

if __name__ == "__main__":
    create_image_rom()