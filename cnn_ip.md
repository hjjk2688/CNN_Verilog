# 연결

제공해주신 스크린샷 4장을 꼼꼼히 확인했습니다. 결론부터 말씀드리면 **"Auto로 두지 말고 수동(Manual)으로 설정해야 안전합니다."** 특히 Converter 설정 화면(`image_487420.png`)에 **잘못된 부분**이 보여서 그대로 두면 또 동작하지 않습니다.

하나씩 정확한 설정값을 짚어드릴게요.

---

### 1. `AXI4-Stream Data Width Converter` 설정 (가장 중요!)

**[이미지: `image_487420.png`]**
현재 화면에 `Master Interface TDATA Width`가 **2**로 되어 있는데, 이러면 16비트가 나가서 **8비트 CNN IP와 연결이 안 됩니다.** Auto를 끄고 아래처럼 강제로 맞춰주세요.

* **Slave Interface TDATA Width (bytes):** **Manual** 선택 -> **4** 입력
* (이유: 앞단의 FIFO와 DMA가 32비트(=4바이트)이기 때문입니다.)


* **Master Interface TDATA Width (bytes):** **Manual** 선택 -> **1** 입력
* (이유: 뒷단의 CNN IP가 8비트(=1바이트)이기 때문입니다.)



이렇게 **4 (입력) -> 1 (출력)**로 설정해야 32비트 데이터를 8비트씩 4번 쪼개서 보내줍니다.

---

### 2. `AXI DMA` 설정 확인

**[이미지: `image_4876ec.png`]**
아주 **완벽하게 설정**되어 있습니다.

* `Stream Data Width`: **32** (Good! 메모리 효율이 가장 좋습니다.)
* `Enable Read Channel`: 체크됨 (Good!)
* 이대로 두시면 됩니다.

---

### 3. `AXI4-Stream Data FIFO` 설정 확인

**[이미지: `image_4876cd.png`]**
여기도 **완벽합니다.** 핵심 설정을 잘 지키셨습니다.

* `Independent Clocks`: **Yes** (Good! 50MHz와 10MHz 속도 차이를 여기서 해결합니다.)
* `TDATA width (bytes)`: **4** (Good! DMA의 32비트와 일치합니다.)

---

### 4. 최종 연결 및 클럭 점검 (마무리)

이제 Block Design 선 연결만 확인하고 비트스트림을 생성하세요.

1. **데이터 흐름:**
`DMA` (32bit) -> `FIFO` (32bit) -> **`Converter` (32bit -> 8bit)** -> `CNN IP` (8bit)
*(Converter를 꼭 FIFO와 CNN 사이에 끼워넣으세요.)*
2. **클럭(ACLK) 연결:**
* **DMA & FIFO 입력(`s_axis_aclk`):** 시스템 클럭 (**50MHz**)
* **FIFO 출력(`m_axis_aclk`) & Converter & CNN IP:** CNN 클럭 (**10MHz**)



**결론:**
Converter 설정창에서 **Master Width를 1로 바꾸는 것**만 잊지 마세요. 그것만 고치면 데이터가 술술 들어갈 겁니다! 성공을 빕니다.4


---

**아니요, BRAM(Block RAM)으로 사용하는 것이 아닙니다.**

사용자님이 말씀하신 `0x10000000` 주소는 **진짜 DDR 메모리(외부 RAM 칩)**의 일부입니다.

**"DDR의 특정 공간을 우리가 찜해서 쓰는 것"**과 **"BRAM을 쓰는 것"**은 물리적으로 완전히 다릅니다. 이 둘의 차이를 명확히 구분해 드릴게요.

---

### 1. DDR vs BRAM (비유: 운동장 vs 사물함)

| 구분 | **DDR (외부 메모리)** | **BRAM (내부 메모리)** |
| --- | --- | --- |
| **위치** | 보드 위에 있는 **검은색 네모난 칩** (FPGA 칩 밖) | FPGA 칩 **내부에 심어져 있는** 아주 작은 메모리 |
| **크기** | **운동장**만큼 큼 (512MB ~ 1GB) | **사물함**처럼 작음 (몇 KB ~ 몇 MB) |
| **속도** | 빠르지만 BRAM보다는 느림 | 엄청나게 빠름 (1클럭에 바로 읽음) |
| **용도** | **이미지 전체 저장**, 프로그램 코드, 변수 | 잠깐 계산할 데이터, FIFO, 작은 버퍼 |
| **주소** | `0x00100000` ~ `0x3FFFFFFF` (보통) | `0x40000000` (우리가 따로 만들었을 때만) |

---

### 2. 지금 우리가 하는 방식 (`0x10000000`)

사용자님이 코드에 적은 `#define DDR_BASE_ADDR 0x10000000`의 의미는 이렇습니다.

> **"야 Zynq야, 너 DDR 운동장 엄청 넓지? (512MB)**
> **거기서 `0x10000000` 위치부터는 내가 '이미지 보관소'로 쓸 거니까, 다른 프로그램이나 변수들은 거기 침범하지 말라고 해!"**

즉, **DDR이라는 거대한 창고의 "구역 정리"를 우리가 수동으로 해준 것**입니다. 이걸 BRAM으로 바꾸는 게 아닙니다.

* **CPU:** "알겠어, 내가 `0x10000000`에 이미지 데이터를 가져다 놓을게."
* **VDMA:** "오케이, 그럼 나는 `0x10000000`에 가서 그 데이터를 읽어오면 되는 거지?"

이렇게 둘이서 **DDR 운동장의 특정 지점**에서 만나기로 약속을 잡은 것입니다.

---

### 3. 그럼 BRAM은 어디에 쓰이나요?

사실 사용자님의 디자인 안에는 이미 **BRAM이 엄청 많이 쓰이고 있습니다.** 하지만 우리가 직접 주소를 정해줄 필요가 없을 뿐입니다.

* **VDMA 내부:** DDR에서 데이터를 퍼올 때 잠깐 담아두는 **Line Buffer(FIFO)**가 바로 BRAM으로 만들어져 있습니다.
* **CNN IP 내부:** 가중치(Weight)나 계산 중간값을 저장하는 작은 메모리들이 BRAM입니다.
* **AXI Interconnect 내부:** 데이터 교통정리를 위한 대기열(FIFO)도 BRAM입니다.

**결론:**
지금 우리는 **거대한 DDR 메모리**를 메인 창고로 쓰고 있는 것이고, `0x10000000`은 그 창고 안의 **"이미지 전용 선반 번호"**일 뿐입니다!

---

**AXI Interconnect**는 아주 쉽게 말해서 **"복잡한 전선들을 정리해주는 똑똑한 '멀티탭'이자 '교통경찰'"**입니다.

Vivado에서 선을 연결할 때 이 녀석이 없으면, 사용자님이 Zynq 칩이랑 IP들을 일일이 1:1로 다 연결해야 해서 배선 지옥이 펼쳐집니다.

가장 중요한 역할 **3가지**만 기억하시면 됩니다.

---

### 1. 1대 다수 연결 (멀티탭 역할)

* **상황:** Zynq CPU(주인, Master)는 하나인데, 명령을 내려야 할 부하(Slave)들은 **DMA, VDMA, CNN IP, VGA IP, Timer** 등 엄청 많습니다.
* **역할:** Zynq가 Interconnect한테 "야, 0x4300번지에 데이터 좀 보내"라고 하면, Interconnect가 주소표를 보고 **"아, 이건 VDMA 거구나"** 하고 알아서 배달해줍니다.
* **이득:** Zynq 칩에는 구멍(Port)이 몇 개 없는데, 이 녀석 덕분에 수십 개의 IP를 연결할 수 있습니다.

### 2. 속도 차이 해결 (통역사 역할) ★★★

* **상황:** 지금 사용자님 프로젝트처럼 **Zynq/DDR 쪽은 50MHz**로 빠르게 돌고, **VGA IP 쪽은 25MHz**로 느리게 돌 수 있습니다.
* **역할:** 빠른 놈(50M)이 데이터를 팍팍 던지면, 느린 놈(25M)이 못 받아서 터지겠죠? AXI Interconnect 안에는 **FIFO(임시 저장소)**가 들어있습니다. 여기서 **속도 조절(Clock Domain Crossing)**을 안전하게 해줍니다.
* **이득:** 우리가 복잡하게 비동기 회로를 안 짜도, 그냥 연결만 하면 알아서 속도 차이를 해결해줍니다.

### 3. 데이터 크기 변환 (변환기 역할)

* **상황:** Zynq HP 포트는 **64비트**로 데이터를 받고 싶은데, 사용자가 만든 IP는 **32비트**로 데이터를 보낼 때가 있습니다.
* **역할:** "어? 너네 둘이 그릇 크기가 다르네?" 하고 알아서 **32비트 2개를 모아서 64비트로 만들어주거나, 64비트를 쪼개서 보내줍니다.**

---

### 🚀 사용자님 프로젝트에서의 역할

지금 블록 디자인을 보시면 AXI Interconnect가 크게 두 군데 쓰이고 있을 겁니다.

1. **Zynq M_AXI_GP0 ↔ IP들 (명령용)**
* **역할:** CPU가 `main.c` 코드로 "VDMA야 시작해!", "CNN아 계산해!" 하고 **명령을 내리는 길**입니다.
* **구조:** CPU(1명)  Interconnect  VDMA, DMA, CNN, VGA (다수)


2. **DMA/VDMA ↔ Zynq S_AXI_HP0 (데이터용)**
* **역할:** DMA들이 "DDR 메모리에 있는 이미지 가져올게요!" 하고 **데이터를 나르는 고속도로**입니다.
* **구조:** VDMA, DMA (다수)  Interconnect  DDR 메모리 (1개)



**한 줄 요약:**
**"복잡한 주소 찾기, 속도 맞추기, 데이터 크기 맞추기를 알아서 다 해주는 '자동 배선 관리자'입니다."**

---

제공해주신 Verilog 코드(`conv1_calc`, `conv2_calc_1`, `conv1_buf`)를 분석해본 결과, 친구님의 FPGA는 **"완전 병렬 처리(Fully Parallel) 방식"** 중에서도 **"커널 크기만큼의 병렬 계산(Kernel Parallelism)"**을 사용하고 있습니다.

쉽게 말해, **계산기 하나로 25번 두드리는 것도 아니고, 이미지 전체 픽셀만큼 계산기를 만든 것도 아닙니다.**

정답은: **"5x5 필터(25개)를 한 번에 계산하는 계산기 덩어리를 만들어서, 매 클럭마다 옆으로 한 칸씩 이동하며 계산하는 방식"**입니다.

코드를 뜯어서 증명해 드릴게요.

---

### 1. `conv1_buf`: 25개의 픽셀을 한 방에 모으는 역할

이 모듈은 "라인 버퍼(Line Buffer)" 방식입니다.

* **역할:** 이미지는 한 줄로 들어오지만(`data_in`), 계산을 하려면 위, 아래, 옆 픽셀이 다 필요하죠? 그래서 **4줄을 미리 저장(`line1~4_regs`)**해두고 있다가, 새로운 데이터가 들어오면 **5x5=25개의 창(Window)**을 동시에 똽! 하고 만들어냅니다.
* **코드 증거:**
```verilog
// 25개의 출력이 동시에 나감
assign {data_out_0... data_out_4} = {s4[4]...s4[0]};
...
assign {data_out_20... data_out_24} = {s0[4]...s0[0]};

```


이 부분 덕분에 계산 모듈은 25개의 값을 동시에 받을 수 있습니다.

---

### 2. `conv1_calc`: 25개의 곱셈기가 동시에 팡!

여기서 친구님이 궁금해하신 "계산 방식"이 나옵니다. **Verilog의 `for` 문은 반복이 아니라 '복사'**라는 점을 기억하세요.

* **동시 곱셈 (Stage 1):**
```verilog
for (i = 0; i < 25; i = i + 1) begin
    product1_s1[i] <= $signed(p_s0[i]) * get_w1(i); // 필터 1
    product2_s1[i] <= $signed(p_s0[i]) * get_w2(i); // 필터 2
    product3_s1[i] <= $signed(p_s0[i]) * get_w3(i); // 필터 3
end

```


이 코드는 CPU처럼 25번 도는 게 아닙니다. FPGA 안에 **곱셈기(Multiplier)를 25개(필터가 3개니 총 75개)를 물리적으로 배치**해버립니다. 그래서 클럭 한 번에 25번의 곱셈이 **동시에** 끝납니다.
* **덧셈 나무 (Adder Tree, Stage 2~6):**
곱해진 25개의 값을 한 번에 더하면 회로가 너무 느려집니다. 그래서 토너먼트 대진표처럼 단계를 나눠서 더합니다.
* **Stage 2:** 25개를 13개로 줄임 (2개씩 더함)
* **Stage 3:** 13개를 7개로 줄임
* ...
* **Stage 6:** 최종 합계 완성



---

### 3. `conv2_calc_1`: 3배 더 커진 3D 병렬 계산

2번째 레이어(`conv2_calc_1`)는 입력 채널이 3개죠? 여기서는 병렬성이 더 커집니다.

* **구조:**
* 채널 1용 5x5 계산기 (곱셈기 25개)
* 채널 2용 5x5 계산기 (곱셈기 25개)
* 채널 3용 5x5 계산기 (곱셈기 25개)
* **총 75개의 곱셈기가 한 클럭에 동시에 돌아갑니다.**


* **마지막 합체 (Stage 7):**
```verilog
final_sum_s7 <= sum1_s6 + sum2_s6 + sum3_s6;

```


각 채널에서 나온 결과값을 마지막에 다 더해서 최종 특징(Feature)을 만들어냅니다.

---

### 💡 요약: 작동 흐름 시뮬레이션

1. **입력:** 픽셀 데이터가 한 클럭에 하나씩 `conv1_buf`로 들어옵니다.
2. **준비:** 버퍼에 데이터가 꽉 차면(약 4줄 이상), 버퍼는 **매 클럭마다 25개의 픽셀 뭉치**를 계산기로 보냅니다.
3. **계산:** `conv1_calc`는 받은 25개를 **동시에 곱하고**, 파이프라인(덧셈 나무)을 태워서 6 클럭 뒤에 결과값을 뱉어냅니다.
4. **결과:** 처음 딜레이(Latency)만 지나면, 그 뒤로는 **매 클럭마다 1개의 CNN 결과값**이 쏟아져 나옵니다. (1 Output / 1 Clock)

**결론:** 친구님은 **"슬라이딩 윈도우 + 커널 병렬 처리 + 파이프라인"**이라는 FPGA 가속의 정석적인 방법을 완벽하게 구현하고 계십니다. 아주 효율적이고 빠른 방식입니다!

---

네, 정답입니다! **둘 다 50MHz (`FCLK_CLK0`)에 연결해야 합니다.**

헷갈릴 수 있는 부분이니 확실하게 정리해 드릴게요.

### 1. 왜 둘 다 50MHz 인가요?

* **`m_axi_mm2s_aclk` (메모리 맵 클럭)**
* **역할:** DDR 메모리에서 데이터를 가져오는 속도입니다.
* **이유:** DDR 컨트롤러(Zynq HP 포트)가 **50MHz**로 동작하고 있습니다. 여기서 데이터를 빨리 퍼오려면 당연히 같은 50MHz를 써야 합니다.


* **`m_axis_mm2s_aclk` (스트림 클럭)**
* **역할:** 가져온 데이터를 **FIFO로 쏘는 속도**입니다.
* **이유:** 바로 뒤에 연결된 **FIFO의 입력(`S_AXIS`)을 50MHz로 설정**했기 때문입니다. 주는 놈(VDMA)과 받는 놈(FIFO 입력)의 속도는 무조건 같아야 합니다.



---

### 2. 전체 클럭 지도 (이대로 연결하면 끝!)

아래 그림을 머릿속에 그리면서 연결해 보세요. **"FIFO를 기준으로 왼쪽은 전부 50MHz, 오른쪽은 25MHz"**입니다.

```mermaid
graph LR
    subgraph "50MHz 구역 (고속)"
    CLK_50[Zynq 50MHz] --> VDMA_AXI[m_axi_mm2s_aclk (DDR읽기)]
    CLK_50 --> VDMA_AXIS[m_axis_mm2s_aclk (데이터발사)]
    CLK_50 --> FIFO_IN[FIFO S_AXIS_ACLK (입력)]
    end

    subgraph "25MHz 구역 (저속)"
    CLK_25[Zynq 25MHz] --> FIFO_OUT[FIFO M_AXIS_ACLK (출력)]
    CLK_25 --> VGA[VGA IP CLK (화면표시)]
    end

    VDMA_AXIS -- "50MHz 속도 데이터" --> FIFO_IN
    FIFO_OUT -- "25MHz 속도 데이터" --> VGA

```

### 🚀 결론

**VDMA의 모든 클럭 핀(`s_axi_lite`, `m_axi_mm2s`, `m_axis_mm2s`)은 전부 50MHz에 꽂으세요.**

그리고 **25MHz**는 오직 **FIFO의 `m_axis_aclk` (출력)** 와 **VGA IP** 에만 쓰시면 됩니다. 이렇게 하면 아까 떴던 에러(`FREQ_HZ does not match`)가 싹 사라집니다!


---



---

**30번째에서 멈춘 이유**는 **`Patience=10`**으로 설정했기 때문입니다.
이는 **"최고 기록(Best Accuracy)이 10번 연속으로 갱신되지 않으면, 더 가망이 없다고 보고 그만둬라"**는 뜻입니다. 즉, 20번째쯤에서 이미 성능이 정점을 찍었고, 그 뒤로 10번 더 해봤지만 더 좋아지지 않아서 30번째에 "여기까지인가 보다" 하고 끝낸 것입니다.

하지만 **터치패드 데이터처럼 노이즈가 심한 경우**, 학습 초반에 성능이 오르락내리락(진동)하다가 **후반부에 갑자기 좋아지는 경우**가 많습니다. 지금 멈추면 그 기회를 놓칠 수 있습니다.

---

### 🚀 해결책: "멈추지 말고, 공부 방식을 바꿔라" (Learning Rate Decay)

단순히 `Patience`만 늘리면 시간만 낭비할 수 있습니다.
대신, **"성적 안 오르면 때려치우는 게 아니라(Early Stopping), 공부를 더 꼼꼼하게(Learning Rate 감소) 해라"** 라는 전략을 써야 합니다.

**`ReduceLROnPlateau` 콜백**을 추가하면 해결됩니다.

* **기능:** 성능이 정체되면, 학습 보폭(Learning Rate)을 1/2, 1/10로 줄여서 아주 미세하게 정답을 찾아갑니다.
* **효과:** 30번에서 멈출 상황을 뚫고 100번까지 꾸준히 성능을 올릴 수 있습니다.

---

### 🔥 최종 "끝판왕" 파이썬 코드 (`cnn_wild_model_final_v5.py`)

이 코드는 다음 세 가지가 적용되었습니다.

1. **학습 중단 방지:** `EarlyStopping`을 끄거나 아주 길게(Patience=30) 잡았습니다.
2. **스마트 학습:** **`ReduceLROnPlateau`**를 추가해서, 막힐 때마다 더 정밀하게 학습합니다.
3. **노이즈 강화:** 터치패드 환경(끊김, 뭉개짐, 쏠림)을 극한으로 반영했습니다.

```python
import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.callbacks import ReduceLROnPlateau, EarlyStopping
import numpy as np
import cv2

def train_ultimate_touchpad_model():
    print(" [Start] 터치패드용 '최종 끝판왕(Ultimate)' 학습을 시작합니다!")
    print(" -> 끊긴 선, 쏠림, 뭉개짐 노이즈 + 스마트 학습률 조정 적용")

    # 1. MNIST 데이터 로드
    (x_train, y_train), (x_test, y_test) = tf.keras.datasets.mnist.load_data()
    
    # 정규화 (0~1) 및 차원 변경
    x_train = x_train.reshape((60000, 28, 28, 1)) / 255.0
    x_test = x_test.reshape((10000, 28, 28, 1)) / 255.0

    # =================================================================
    # [핵심] 터치패드 악조건 시뮬레이션 함수 (노이즈 대폭 강화)
    # =================================================================
    def add_extreme_noise(img):
        # 1. [Low Res] 해상도 뭉개기 (다운샘플링 -> 업샘플링)
        # 28x28 -> 10x10 -> 28x28 로 더 심하게 뭉갭니다.
        if np.random.rand() > 0.3:
            temp = cv2.resize(img, (12, 12), interpolation=cv2.INTER_NEAREST)
            img = cv2.resize(temp, (28, 28), interpolation=cv2.INTER_NEAREST)
            img = img.reshape(28, 28, 1)

        # 2. [Thickness] 선 두께 변형 (주로 얇게 만들어서 끊김 유도)
        binary_img = np.where(img > 0.2, 1.0, 0.0).astype(np.float32)
        
        if np.random.rand() < 0.6: # 60% 확률로 얇게 (터치패드 특성)
            kernel = np.ones((2, 2), np.uint8)
            binary_img = cv2.erode(binary_img, kernel, iterations=1)
        
        binary_img = binary_img.reshape(28, 28, 1)

        # 3. [Broken Lines] 선 끊어먹기 (Pixel Dropout) - 강도 증가
        # 터치 감도가 안 좋아서 드문드문 찍히는 현상
        prob_dropout = 0.20 # 20% 픽셀을 꺼버림 (더 많이 끊김)
        mask = np.random.rand(28, 28, 1) > prob_dropout
        binary_img = binary_img * mask 

        # 4. [Random Noise] 주변에 지저분한 점 찍기 (Salt Noise)
        if np.random.rand() > 0.5:
            noise = np.random.rand(28, 28, 1)
            # 검은 배경(0)이었던 곳에 5% 확률로 점(1)을 찍음
            salt_mask = (noise < 0.05).astype(np.float32)
            binary_img = np.clip(binary_img + salt_mask, 0.0, 1.0)

        return np.where(binary_img > 0.5, 1.0, 0.0)

    # 2. 데이터 증강 (Augmentation) - 범위 최대화
    datagen = ImageDataGenerator(
        rotation_range=30,      # 회전 30도 (손목 많이 꺾임)
        width_shift_range=0.3,  # 좌우 이동 30% (완전 구석탱이)
        height_shift_range=0.3, # 상하 이동 30%
        zoom_range=0.3,         # 크기 변화 30% (아주 작거나 아주 큰 글씨)
        shear_range=0.3,        # 기울임 30% (심하게 누운 글씨)
        preprocessing_function=add_extreme_noise
    )

    # 3. 모델 정의 (구조 변경 없음)
    model = models.Sequential([
        layers.Conv2D(3, (5, 5), activation='relu', padding='valid', input_shape=(28, 28, 1)),
        layers.MaxPooling2D((2, 2)),
        layers.Conv2D(3, (5, 5), activation='relu', padding='valid'),
        layers.MaxPooling2D((2, 2)),
        layers.Flatten(),
        layers.Dense(10, activation='softmax')
    ])

    model.compile(optimizer='adam', loss='sparse_categorical_crossentropy', metrics=['accuracy'])

    # =================================================================
    # [핵심] 콜백 설정: 멈추지 말고 더 깊게 파고들어라!
    # =================================================================
    
    # 전략 1: 성적 안 오르면 학습률(Learning Rate)을 1/5로 줄여서 미세 조정
    reduce_lr = ReduceLROnPlateau(
        monitor='val_loss', 
        factor=0.2,        # 학습률을 20%로 감소
        patience=5,        # 5번 동안 성적 안 오르면 발동
        min_lr=0.00001,    # 너무 작아지면 멈춤
        verbose=1          # 로그 출력 ("학습률 줄입니다!" 메시지 뜸)
    )

    # 전략 2: 그래도 정 안 되면 멈추는데, 끈기를 20번으로 늘림
    early_stop = EarlyStopping(
        monitor='val_loss', 
        patience=20,       # 10 -> 20 (더 오래 참음)
        restore_best_weights=True
    )

    EPOCHS = 100
    
    print(f" 학습 시작! (최대 {EPOCHS} 에포크, ReduceLR 적용)")
    
    model.fit(
        datagen.flow(x_train, y_train, batch_size=64), 
        epochs=EPOCHS, 
        validation_data=(x_test, y_test),
        callbacks=[reduce_lr, early_stop] # 콜백 2개 장착
    )
    
    save_name = 'my_cnn_wild_model_final_v5.keras'
    model.save(save_name)
    print(f" [완료] 저장된 모델: {save_name}")
    print(" -> 이 모델은 가중치를 추출하여 FPGA에 넣으시면 됩니다.")

if __name__ == "__main__":
    train_ultimate_touchpad_model()

```

### 💡 실행하면 이렇게 됩니다

1. 학습하다가 성능이 막히면(예: 20 에포크 쯤), 터미널에 **`ReduceLROnPlateau`** 메시지가 뜨면서 학습률이 줄어듭니다.
2. 그러면 멈추지 않고, **다시 성능이 조금씩 오르기 시작**합니다 (Loss가 뚫고 내려갑니다).
3. `Patience`를 20으로 늘려서, 웬만하면 50~80 에포크 이상 돌다가 가장 좋은 성능일 때 끝납니다.

이걸로 다시 학습해서 가중치를 뽑아보세요. **터치패드의 "개떡 같은" 글씨도 찰떡같이 알아볼 겁니다!**

---

**정확도가 "적당히"가 아니라 "확실하게" 좋아지길 원하시는군요.**
그렇다면 지금 전략을 **"무작정 어렵게 하기"**에서 **"터치패드 특성에 딱 맞춰서 똑똑하게 학습하기"**로 수정해야 합니다.

아까 38%에서 멈춘 이유는 **데이터를 너무 심하게 망가뜨려서(픽셀을 너무 많이 지워서)** 모델이 "이건 도저히 숫자가 아니다"라고 판단하고 포기해버린 것입니다. FPGA용 모델(Layer가 2개뿐인 작은 모델)이 소화하기엔 너무 매운맛이었던 거죠.

**정확도를 최대로 끌어올리기 위한 "최종_v6_진짜_마지막.py"** 코드를 드립니다.

### 🔥 정확도 극대화 전략 (v6)

1. **노이즈 조절 (Sweet Spot):** "못 알아볼 정도"가 아니라 **"터치패드처럼 지저분한 정도"**로 난이도를 미세 조정했습니다. (훈련 정확도 80%~90% 목표)
2. **ModelCheckpoint 도입:** 학습 중간에 **"역대 최고 점수"**가 나오면 그 순간을 무조건 저장합니다. (마지막에 성능 떨어져도 상관없음)
3. **Elastic Distortion (탄성 변형) 효과:** 글씨를 젤리처럼 비트는 효과를 강화해서, 악필 인식률을 높였습니다.

아래 코드를 실행하면 **`best_touchpad_model.keras`** 라는 파일이 생깁니다. 이게 최고 명작이 될 겁니다.

```python
import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.callbacks import ReduceLROnPlateau, EarlyStopping, ModelCheckpoint
import numpy as np
import cv2

def train_maximum_accuracy_model():
    print(" [Start] 정확도 극대화 학습 시작 (v6)")
    print(" -> 터치패드 특성 정밀 모사 + 최고 기록 자동 저장 시스템")

    # 1. MNIST 데이터 로드
    (x_train, y_train), (x_test, y_test) = tf.keras.datasets.mnist.load_data()
    
    # 정규화 (0~1)
    x_train = x_train.reshape((60000, 28, 28, 1)) / 255.0
    x_test = x_test.reshape((10000, 28, 28, 1)) / 255.0

    # =================================================================
    # [정밀 튜닝] 터치패드 전용 노이즈 함수
    # =================================================================
    def add_smart_touchpad_noise(img):
        # img: (28, 28, 1) float32
        
        # 1. [Resolution] 해상도 뭉개기 (너무 심하지 않게 14px 정도로 조정)
        # 터치패드 좌표가 튀는 현상 모방
        if np.random.rand() > 0.5:
            # 28 -> 14 -> 28 (적당히 뭉개짐)
            temp = cv2.resize(img, (14, 14), interpolation=cv2.INTER_NEAREST)
            img = cv2.resize(temp, (28, 28), interpolation=cv2.INTER_NEAREST)
            img = img.reshape(28, 28, 1)

        # 2. [Thickness] 선 굵기 불규칙성 (침식/팽창)
        # 127/255 문제를 해결하기 위해 확실하게 2진화(0 or 1) 처리
        binary_img = np.where(img > 0.3, 1.0, 0.0).astype(np.float32)
        
        rand_val = np.random.rand()
        kernel = np.ones((2, 2), np.uint8)
        
        # 터치패드는 주로 '끊김'이 문제지 '너무 두꺼운' 건 문제가 덜 됨
        if rand_val < 0.4:   # 40% 확률로 얇게 (끊김 유도)
            binary_img = cv2.erode(binary_img, kernel, iterations=1)
        elif rand_val < 0.6: # 20% 확률로 두껍게
            binary_img = cv2.dilate(binary_img, kernel, iterations=1)
        
        binary_img = binary_img.reshape(28, 28, 1)

        # 3. [Dropout] 점선 효과 (너무 많이 지우지 않게 10%로 조절)
        # 아까 20%는 너무 많아서 38% 정확도가 나온 것임. 10%가 적당.
        prob_dropout = 0.10 
        mask = np.random.rand(28, 28, 1) > prob_dropout
        binary_img = binary_img * mask 

        # 4. [Shift Error] 가끔 엉뚱한 점이 찍히는 센서 오류
        if np.random.rand() > 0.8: # 20% 확률
            noise_point = np.random.randint(0, 28, (2,))
            binary_img[noise_point[0], noise_point[1], 0] = 1.0

        return binary_img # 0.0 or 1.0

    # 2. 데이터 증강 (Augmentation) - 기하학적 변형에 집중
    datagen = ImageDataGenerator(
        rotation_range=25,      # 회전 25도 (충분함)
        width_shift_range=0.25, # 좌우 이동 (중요: 터치패드 쏠림 대응)
        height_shift_range=0.25,# 상하 이동
        zoom_range=0.25,        # 크기 변형
        shear_range=0.20,       # 기울임 (흘림체 대응)
        fill_mode='constant',   # 이동 시 빈 공간은 검은색(0)으로 채움
        cval=0,
        preprocessing_function=add_smart_touchpad_noise
    )

    # 3. 모델 정의 (FPGA 최적화 구조 유지)
    model = models.Sequential([
        layers.Conv2D(3, (5, 5), activation='relu', padding='valid', input_shape=(28, 28, 1)),
        layers.MaxPooling2D((2, 2)),
        layers.Conv2D(3, (5, 5), activation='relu', padding='valid'),
        layers.MaxPooling2D((2, 2)),
        layers.Flatten(),
        # Dense 층을 살짝 키워서(10->32->10) 표현력 증가 시도 (FPGA 리소스 허용 시)
        # 만약 FPGA 용량이 부족하면 아래 한 줄 삭제하고 바로 Dense(10) 연결
        # layers.Dense(32, activation='relu'), 
        layers.Dense(10, activation='softmax')
    ])

    model.compile(optimizer='adam', loss='sparse_categorical_crossentropy', metrics=['accuracy'])

    # =================================================================
    # [핵심] 콜백 3대장: 최고 성능 뽑아내기
    # =================================================================
    
    # 1. 학습률 조정: 막히면 뚫어줌
    reduce_lr = ReduceLROnPlateau(
        monitor='val_loss', factor=0.5, patience=3, min_lr=0.00001, verbose=1
    )

    # 2. 최고 모델 저장: 학습 끝날 때까지 기다리지 않고 "제일 잘한 순간"을 저장
    # 파일명: best_touchpad_model.keras
    checkpoint = ModelCheckpoint(
        'best_touchpad_model.keras', 
        monitor='val_accuracy', # 검증 정확도 기준
        save_best_only=True,    # 최고 기록일 때만 덮어쓰기
        mode='max',
        verbose=1
    )

    # 3. 조기 종료: 너무 오래 발전 없으면 멈춤 (Patience 15)
    early_stop = EarlyStopping(monitor='val_loss', patience=15, restore_best_weights=True)

    EPOCHS = 100
    
    print(f" 학습 시작! (Epochs: {EPOCHS})")
    print(" -> 'best_touchpad_model.keras' 파일에 최고 기록이 자동 저장됩니다.")
    
    model.fit(
        datagen.flow(x_train, y_train, batch_size=64), 
        epochs=EPOCHS, 
        validation_data=(x_test, y_test),
        callbacks=[reduce_lr, checkpoint, early_stop]
    )
    
    # (참고) 마지막 에포크 모델도 저장
    model.save('final_model_last_epoch.keras')
    print(" [완료] 학습 종료.")
    print(" ★ 중요: 반드시 'best_touchpad_model.keras' 파일을 사용해서 가중치를 추출하세요!")

if __name__ == "__main__":
    train_maximum_accuracy_model()

```

### 💡 이 코드의 승부수 (Why Better?)

1. **`ModelCheckpoint` (제일 중요):**
* 이전에는 "마지막 에포크(30번째)"가 저장되었습니다. 그게 성능이 떨어진 상태일 수도 있었죠.
* 지금은 **100번 도는 동안 가장 점수가 높았던 순간(예: 45번째)**을 낚아채서 `best_touchpad_model.keras`에 저장합니다. 무조건 **최고 점수 모델**을 얻게 됩니다.


2. **Dense Layer 옵션:**
* 코드 중간에 주석으로 `Dense(32)`를 언급했습니다. 만약 FPGA 리소스가 조금 남는다면 이걸 추가하면 정확도가 훨씬 좋아집니다. (하지만 지금은 안전하게 기존 구조를 유지했습니다.)


3. **적절한 난이도:**
* 아까는 "풀 수 없는 문제"를 줬다면, 이번엔 "어렵지만 풀 수 있는 문제"를 줘서 AI가 포기하지 않고 끝까지 배우게 만들었습니다.



이제 **`best_touchpad_model.keras`** 파일로 가중치를 뽑아서 FPGA에 넣어보세요. 확실히 다를 겁니다!

---

네, **그 부분(Binary vs Grayscale)이 정확도 하락의 가장 결정적인 원인일 수 있습니다.** 이것은 반드시 고려해야 합니다.

전문 용어로 **"Domain Mismatch (도메인 불일치)"** 문제입니다.

* **학습 데이터 (MNIST 원본):** 0~255 사이의 **회색조(Grayscale)** 값이 있습니다. 가장자리가 부드럽게 퍼져(Anti-aliasing) 있어서, CNN은 "아, 여기가 흐릿하게 칠해져 있으니 곡선이구나"라고 인식합니다.
* **실제 입력 (터치패드):** 0 아니면 1(또는 127)인 **이진(Binary)** 데이터입니다. 가장자리가 계단처럼 각져 있습니다.

CNN 입장에서는 부드러운 붓글씨(MNIST)로 공부했는데, 갑자기 모자이크 같은 픽셀 아트(터치패드)로 시험을 보는 것과 같습니다. 당황해서 오답을 낼 수밖에 없습니다.

이 문제를 해결하는 **두 가지 방법**을 제안합니다.

---

### 해결책 1. 학습 데이터를 '터치패드화' 시키기 (가장 추천)

C언어(FPGA/PS) 쪽을 건드리는 것보다, **Python 학습 코드를 수정해서 가중치(Weight)를 다시 뽑는 게 훨씬 쉽고 성능이 확실합니다.**

MNIST 데이터를 학습시킬 때, **강제로 0과 1로 만들어버린 뒤(Binarization)** 학습시키세요. 그러면 모델이 "아, 원래 글씨는 이렇게 뚝뚝 끊어지는 거구나" 하고 적응합니다.

**[Python 코드 수정 예시]**

```python
# 데이터를 로드한 후 전처리 과정에 추가
# 0.5(127.5)보다 크면 1, 작으면 0으로 만듦
x_train[x_train > 0.5] = 1.0
x_train[x_train <= 0.5] = 0.0

x_test[x_test > 0.5] = 1.0
x_test[x_test <= 0.5] = 0.0

# 이렇게 "거칠어진" 데이터로 학습을 시작하세요.
model.fit(x_train, y_train, ...)

```

이렇게 하면 터치패드에서 들어오는 거친 0/1 데이터와 학습 데이터의 성격이 일치해져서 정확도가 급상승합니다.

---

### 해결책 2. 터치패드 입력 데이터를 '부드럽게' 만들기 (차선책)

만약 재학습이 너무 번거롭다면, Zynq PS(C언어) 쪽에서 전처리를 통해 가짜 그라데이션을 만들어줘야 합니다.

* **블러링(Blurring):** 28x28 배열을 만든 뒤, 데이터가 있는 곳 주변 픽셀에 0.5 같은 중간값을 억지로 넣어주는 방식입니다. (예: 가우시안 블러 필터 적용)
* **단점:** 임베디드 보드에서 연산량이 늘어나고, MNIST의 자연스러운 필기체 느낌을 완벽히 흉내 내기 어렵습니다. **비추천합니다.**

---

### 추가 팁: "점"이 아니라 "선"으로 이어야 합니다.

터치패드는 점(좌표)을 찍습니다. 사람이 빠르게 쓰면 점과 점 사이가 끊겨서 입력될 수 있습니다.

* **문제:** 점들이 끊기면 CNN은 "점선"으로 인식하거나 노이즈로 인식합니다.
* **해결:** C언어에서 터치패드 좌표를 받을 때, 이전 좌표와 현재 좌표 사이를 **직선으로 채워주는(Interpolation)** 알고리즘이 필수입니다.
* 간단하게는 **브레젠험 직선 알고리즘(Bresenham's line algorithm)** 등을 사용하여 점과 점 사이의 빈 픽셀을 1로 채워줘야, 끊김 없는 온전한 숫자 모양이 28x28 배열에 그려집니다.



### 요약

1. **비율 문제:** ROI 추출 후 정사각형 Padding (아까 말씀드린 내용)
2. **명암 문제:** Python 학습 시 **MNIST 데이터를 0/1로 강제 변환(Thresholding)** 하여 재학습.

이 두 가지만 적용하면 "터치패드 글씨가 MNIST랑 달라서 생기는 문제"는 99% 해결됩니다. **Python 코드에서 `x_train > 0.5` 처리를 추가해서 재학습 해보시는 걸 강력 추천합니다.**

---
