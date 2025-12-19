import tensorflow as tf
import numpy as np

def save_hex(data, name, scale=127):
    # 1. Quantization & Clipping
    scaled = np.round(data * scale)
    clipped = np.clip(scaled, -128, 127).astype(int)
    
    # 2. Flatten (이미 transpose가 된 상태에서 펼침)
    flat_data = clipped.flatten()
    
    # 3. Hex 변환
    with open(name, 'w') as f:
        hex_data = [format(x & 0xFF, '02x') for x in flat_data]
        f.write(" ".join(hex_data))
    
    print(f"{name} 저장 완료 (개수: {len(flat_data)})")

# 모델 로드
model = tf.keras.models.load_model('my_cnn_model.keras')

# --- 1. Conv1 (conv2d) ---
w1, b1 = model.get_layer('conv2d').get_weights()
# Keras: (5, 5, 1, 3) -> Verilog 기대: (3, 5, 5, 1)
w1_fixed = w1.transpose(3, 0, 1, 2) 
save_hex(w1_fixed, 'conv1_w.txt')
save_hex(b1, 'conv1_b.txt')

# --- 2. Conv2 (conv2d_1) ---
w2, b2 = model.get_layer('conv2d_1').get_weights()
# Keras: (5, 5, 3, 3) -> Verilog 기대: (3, 5, 5, 3)
w2_fixed = w2.transpose(3, 0, 1, 2) 
save_hex(w2_fixed, 'conv2_w.txt')
save_hex(b2, 'conv2_b.txt')

# --- 3. FC (dense) ---
w_fc, b_fc = model.get_layer('dense').get_weights()
# Keras: (48, 10) -> Verilog 기대: (10, 48)
w_fc_fixed = w_fc.transpose(1, 0) 
save_hex(w_fc_fixed, 'fc_w.txt')
save_hex(b_fc, 'fc_b.txt')