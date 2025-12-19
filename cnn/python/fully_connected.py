import os

def generate_fc_rom(input_txt, output_v):
    if not os.path.exists(input_txt):
        print(f"Error: {input_txt} 파일이 없습니다.")
        return

    # 1. 가중치 읽기
    with open(input_txt, 'r') as f:
        weights = f.read().split()

    if len(weights) < 480:
        print(f"Warning: 가중치가 {len(weights)}개뿐입니다. 480개가 필요합니다.")
    
    # 2. Verilog 함수 생성
    verilog_code = []
    verilog_code.append("// --- FC Layer Weights ROM (Generated) ---")
    verilog_code.append("function signed [7:0] get_weight(input [9:0] addr);")
    verilog_code.append("    case(addr)")
    
    for i, w_hex in enumerate(weights):
        if i >= 480: break # 최대 480개까지만 생성
        verilog_code.append(f"        10'd{i}: get_weight = 8'sh{w_hex};")
        
    verilog_code.append("        default: get_weight = 8'sh00;")
    verilog_code.append("    endcase")
    verilog_code.append("endfunction")

    # 3. 파일 저장
    with open(output_v, 'w') as f:
        f.write('\n'.join(verilog_code))
    print(f"성공: {output_v} 생성 완료!")

if __name__ == "__main__":
    generate_fc_rom('fc_w.txt', 'fc_weight_rom.v')