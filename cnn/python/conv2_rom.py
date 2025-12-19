import os

def generate_conv2_split_roms(input_txt):
    if not os.path.exists(input_txt):
        print(f"Error: {input_txt} 파일이 없습니다.")
        return

    with open(input_txt, 'r') as f:
        all_weights = f.read().split()

    # 225개를 75개씩 3개의 모듈용으로 나눔
    # Keras 순서: [Filter0(75개), Filter1(75개), Filter2(75개)]
    for m_idx in range(3):
        start = m_idx * 75
        module_weights = all_weights[start : start + 75]
        
        verilog_code = []
        # 각 모듈(calc_1~3)은 내부에서 get_w1, get_w2, get_w3 함수 3개를 가짐 (각 25개입)
        for f_idx in range(3):
            sub_start = f_idx * 25
            sub_weights = module_weights[sub_start : sub_start + 25]
            f_name = f"get_w{f_idx+1}"
            
            verilog_code.append(f"function signed [7:0] {f_name}(input [4:0] addr);")
            verilog_code.append("    case(addr)")
            for i, w_hex in enumerate(sub_weights):
                verilog_code.append(f"        5'd{i}: {f_name} = 8'sh{w_hex};")
            verilog_code.append(f"        default: {f_name} = 8'sh00;")
            verilog_code.append("    endcase")
            verilog_code.append("endfunction\n")
            
        output_name = f"conv2_rom{m_idx+1}.v"
        with open(output_name, 'w') as f:
            f.write('\n'.join(verilog_code))
        print(f"{output_name} 생성 완료")

if __name__ == "__main__":
    generate_conv2_split_roms('conv2_w.txt')