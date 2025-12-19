import os

def generate_conv1_rom(input_txt, output_v):
    if not os.path.exists(input_txt):
        print(f"Error: {input_txt} 파일을 찾을 수 없습니다.")
        return

    # 1. 가중치 데이터 읽기
    all_weights = []
    with open(input_txt, 'r') as f:
        for line in f:
            all_weights.extend(line.strip().split())
    
    # 2. 75개를 25개씩 3개의 필터 그룹으로 분리
    # Keras 가중치 순서상 [Filter0(25개), Filter1(25개), Filter2(25개)] 순입니다.
    filter_groups = [all_weights[0:25], all_weights[25:50], all_weights[50:75]]
    
    verilog_code = []
    verilog_code.append("// --- Conv1 Layer Weights ROM (Generated) ---")

    for idx, weights in enumerate(filter_groups):
        f_name = f"get_w{idx+1}"  # get_w1, get_w2, get_w3
        
        verilog_code.append(f"function signed [7:0] {f_name}(input [4:0] addr);")
        verilog_code.append("    case(addr)")
        
        for i, w_hex in enumerate(weights):
            verilog_code.append(f"        5'd{i}: {f_name} = 8'sh{w_hex};")
            
        verilog_code.append(f"        default: {f_name} = 8'sh00;")
        verilog_code.append("    endcase")
        verilog_code.append("endfunction\n")
    
    # 3. 파일 저장
    with open(output_v, 'w') as f:
        f.write('\n'.join(verilog_code))
    
    print(f"성공: {output_v} 생성 완료 (함수: get_w1, get_w2, get_w3)")

if __name__ == "__main__":
    generate_conv1_rom('conv1_w.txt', 'conv1_weight_rom.v')