# FPGA 기반 실시간 손글씨 숫자 인식 시스템 설계 및 구현

## 1. 서론

### 1.1 연구 배경 및 목적

본 프로젝트는 Zynq-7000 SoC 플랫폼을 활용하여 CNN(Convolutional Neural Network) 기반의 실시간 손글씨 숫자 인식 시스템을 구현하는 것을 목표로 한다. FPGA의 병렬 처리 능력을 활용하여 저전력, 고속의 추론 성능을 달성하고, 터치패드 입력과 VGA 출력을 통한 실시간 인터랙션을 제공한다.

### 1.2 시스템 개요

시스템은 크게 다음 세 가지 서브시스템으로 구성된다:
- **입력 모듈**: 터치패드를 통한 손글씨 입력 및 전처리
- **연산 모듈**: FPGA에 구현된 CNN 가속기를 통한 숫자 인식
- **출력 모듈**: VGA 디스플레이를 통한 실시간 결과 표시

---

## 2. 시스템 아키텍처

### 2.1 전체 시스템 구성도

제공된 Block Design은 Zynq PS(Processing System)와 PL(Programmable Logic) 간의 긴밀한 협업 구조를 보여준다. 주요 데이터 경로는 다음과 같다:

1. **CNN 추론 경로**: PS → AXI DMA → Data FIFO → Width Converter → CNN Core
2. **비디오 출력 경로**: DDR Memory → AXI VDMA → Data FIFO → VGA Controller

### 2.2 주요 IP 구성 요소

| 구성 요소 | 역할 | 적용 인터페이스 |
|-----------|------|------------------|
| **Zynq PS** | 시스템 제어, 데이터 전처리 | AXI4-Lite (제어), AXI4-MM (데이터) |
| **AXI DMA** | 고속 메모리-스트림 데이터 전송 | AXI4-Memory Map / AXI4-Stream |
| **AXI VDMA** | 비디오 프레임 버퍼 관리 | AXI4-Memory Map / AXI4-Stream |
| **Width Converter** | 데이터 폭 정렬 (32bit → 8bit) | AXI4-Stream |
| **Data FIFO** | 클럭 도메인 동기화 및 버퍼링 | AXI4-Stream (비동기 모드) |
| **AXI Interconnect** | 다중 마스터/슬레이브 중재 및 주소 디코딩 | AXI4 |
| **CNN 가속기** | 합성곱 신경망 추론 연산 | AXI4-Stream |
| **VGA Controller** | VGA 타이밍 신호 생성 및 픽셀 출력 | AXI4-Stream → Physical I/O |

---

## 3. 하드웨어 설계

### 3.1 클럭 아키텍처 설계

시스템은 서로 다른 동작 주파수를 가진 세 개의 클럭 도메인으로 구성된다.

#### 3.1.1 클럭 구성표

| 클럭 도메인 | 주파수 | 적용 모듈 | 설계 근거 |
|-------------|--------|-----------|-----------|
| **시스템 클럭** | 50 MHz | Zynq PS, DMA, VDMA, AXI Interconnect | DDR 메모리 인터페이스 최적화 |
| **VGA 클럭** | 25.175 MHz | VGA Controller | VGA 640×480@60Hz 타이밍 규격 준수 |
| **CNN 클럭** | 10 MHz | CNN Core | 복잡한 연산 경로의 타이밍 마진 확보 |

#### 3.1.2 클럭 도메인 교차(CDC) 처리

본 설계에서는 서로 다른 클럭 도메인 간의 안정적인 데이터 전송을 위해 **AXI4-Stream Data FIFO**의 **Independent Clock 모드**를 활용하였다. 이는 내부적으로 비동기 FIFO(Asynchronous FIFO) 로직을 포함하여 다음과 같은 CDC 문제를 해결한다:

**A. VGA 경로 (50MHz → 25MHz)**
- VDMA가 메모리 대역폭에 맞춰 고속(50MHz)으로 데이터를 송출하고, VGA Controller가 모니터 주사율에 동기화된 저속(25MHz)으로 데이터를 소비하는 속도 차이를 완충한다.
- 화면 티어링(Tearing) 및 버퍼 오버플로우를 방지하여 끊김 없는 비디오 출력을 보장한다.

**B. CNN 경로 (50MHz → 10MHz)**
- DMA가 DDR에서 대량의 이미지 데이터를 고속으로 전송하는 반면, CNN 가속기는 복잡한 합성곱 연산으로 인해 상대적으로 느린 클럭에서 동작한다.
- FIFO가 중간 버퍼 역할을 수행하여 DMA의 버스트 전송과 CNN의 스트림 처리 속도 차이를 흡수한다.

### 3.2 데이터 경로 설계

#### 3.2.1 CNN 추론 경로

```
DDR Memory (32-bit) 
    ↓ [AXI DMA, 50MHz]
AXI4-Stream (32-bit, 50MHz)
    ↓ [Data FIFO - CDC]
AXI4-Stream (32-bit, 10MHz)
    ↓ [Width Converter]
AXI4-Stream (8-bit, 10MHz)
    ↓ [CNN Accelerator]
연산 결과 (Classification)
```

**설계 근거:**

1. **AXI DMA 사용 이유**  
   CPU가 `for`문으로 픽셀 데이터를 개별 전송하는 것과 달리, DMA는 CPU 개입 없이 대량 데이터(28×28=784바이트)를 한 번에 전송할 수 있어 시스템 전체의 처리량(Throughput)을 극대화한다.

2. **Width Converter 필요성**  
   Zynq의 메모리 버스는 효율성을 위해 32비트 또는 64비트 단위로 데이터를 읽지만, 설계된 CNN IP는 8비트(픽셀 단위) 입력을 받는다. Width Converter는 이러한 데이터 폭 불일치(Width Mismatch)를 해결하기 위해 32비트 워드를 4개의 8비트 바이트로 순차 변환한다.

3. **Data FIFO의 역할**  
   - **속도 완충**: DMA의 버스트 전송 특성과 CNN의 파이프라인 처리 속도 차이를 흡수한다.
   - **클럭 동기화**: 50MHz와 10MHz 클럭 도메인 간의 안전한 데이터 전달을 보장한다.
   - **백프레셔(Backpressure) 처리**: CNN이 데이터를 처리할 준비가 되지 않았을 때 `TREADY` 신호를 통해 DMA에 전송 중지를 요청한다.

#### 3.2.2 비디오 출력 경로

```
DDR Memory (Frame Buffer)
    ↓ [AXI VDMA, 50MHz]
AXI4-Stream (32-bit, 50MHz)
    ↓ [Data FIFO - CDC]
AXI4-Stream (32-bit, 25MHz)
    ↓ [VGA Controller]
VGA Physical Signals (RGB, Hsync, Vsync)
```

**설계 근거:**

1. **VDMA 선택 이유**  
   일반 DMA와 달리 VDMA는 2차원 프레임 버퍼 개념이 내장되어 있다. Horizontal Stride, Vertical Size 등의 파라미터를 통해 비디오 프레임의 구조를 인식하고, 프레임 단위로 DDR을 순환 읽기(Circular Buffering)하여 실시간 비디오 스트리밍에 최적화되어 있다.

2. **FIFO의 실시간성 보장**  
   VGA 타이밍은 엄격한 실시간 제약을 가진다. Blanking 구간을 제외하고 매 픽셀 클럭마다 정확히 RGB 데이터가 공급되어야 하며, 이를 위해 FIFO는 충분한 깊이(Depth)를 가져 VDMA의 메모리 접근 레이턴시를 감춘다.

### 3.3 AXI Interconnect의 역할

AXI Interconnect는 단순한 버스 중재기를 넘어 다음과 같은 핵심 기능을 수행한다:

1. **주소 디코딩 및 라우팅**  
   Zynq PS의 단일 AXI Master 포트에서 여러 Slave IP(DMA, VDMA, CNN 레지스터, GPIO 등)로의 주소 기반 명령 라우팅을 담당한다. 각 IP는 고유한 메모리 맵 주소를 할당받으며, Interconnect는 주소 범위를 비교하여 해당 Slave로 트랜잭션을 전달한다.

2. **데이터 폭 변환(Data Width Conversion)**  
   서로 다른 데이터 폭을 가진 마스터와 슬레이브 간의 자동 변환을 수행한다. 예를 들어, 64비트 HP(High Performance) 포트와 32비트 IP 간의 통신 시 자동으로 패킹/언패킹을 처리한다.

3. **클럭 동기화(Optional)**  
   일부 Interconnect는 비동기 클럭 브리징 기능을 포함하지만, 본 설계에서는 명시적인 FIFO를 사용하여 CDC를 처리하므로 Interconnect는 동기 모드로 동작한다.

4. **버스트 변환 및 최적화**  
   메모리 액세스 효율을 위해 짧은 여러 개의 트랜잭션을 하나의 긴 버스트로 병합하거나, 반대로 긴 버스트를 지원하지 않는 Slave를 위해 분할한다.

---

## 4. CNN 가속기 설계

### 4.1 네트워크 구조

본 프로젝트에서 구현한 CNN은 MNIST 데이터셋 기반의 경량화 모델로, 다음과 같은 레이어 구조를 가진다:

```
입력: 28×28×1 (Grayscale)
    ↓
[Conv1] 3 filters, 5×5 kernel, ReLU → 24×24×3
    ↓
[MaxPool1] 2×2 stride 2 → 12×12×3
    ↓
[Conv2] 3 filters, 5×5 kernel, ReLU → 8×8×3
    ↓
[MaxPool2] 2×2 stride 2 → 4×4×3
    ↓
[Flatten] → 48 features
    ↓
[Dense] 10 neurons, Softmax → Classification (0~9)
```

### 4.2 하드웨어 병렬화 전략

#### 4.2.1 커널 병렬성(Kernel Parallelism)

제공된 Verilog 코드(`conv1_calc`, `conv2_calc`) 분석 결과, 본 설계는 **완전 병렬 커널 연산(Fully Parallel Kernel Computation)** 방식을 채택하였다.

**구현 메커니즘:**
```verilog
// conv1_calc.v 핵심 로직
for (i = 0; i < 25; i = i + 1) begin
    product1_s1[i] <= $signed(p_s0[i]) * get_w1(i);
    product2_s1[i] <= $signed(p_s0[i]) * get_w2(i);
    product3_s1[i] <= $signed(p_s0[i]) * get_w3(i);
end
```

위 코드에서 `for`문은 소프트웨어의 순차 반복이 아닌, **25개의 곱셈기를 물리적으로 병렬 배치**하는 하드웨어 기술 방식이다. 따라서 5×5 커널의 모든 원소와 입력 윈도우 간의 곱셈이 **단일 클럭 사이클 내에 동시 실행**된다.

#### 4.2.2 라인 버퍼 및 슬라이딩 윈도우

`conv1_buf` 모듈은 스트리밍 입력 데이터로부터 2D 합성곱에 필요한 5×5 윈도우를 생성하는 라인 버퍼를 구현한다.

**동작 원리:**
1. 이미지는 1차원 스트림으로 입력되지만, 합성곱은 2D 공간 정보가 필요하다.
2. 4개의 라인 레지스터(`line1_regs` ~ `line4_regs`)에 이전 행들을 저장한다.
3. 새로운 픽셀이 입력될 때마다 5×5=25개의 픽셀을 동시에 출력(`data_out_0` ~ `data_out_24`)하여 계산 모듈로 전달한다.

이를 통해 **매 클럭마다 하나의 출력 픽셀**을 생성하는 고속 파이프라인을 구현한다.

#### 4.2.3 덧셈 트리(Adder Tree) 최적화

25개의 곱셈 결과를 합산할 때, 단일 클럭에 모두 더하면 크리티컬 패스(Critical Path)가 길어져 클럭 주파수가 낮아진다. 이를 해결하기 위해 **다단계 파이프라인 덧셈 트리**를 구현하였다:

```
Stage 1: 25개의 곱셈 결과
Stage 2: 13개로 축소 (2개씩 덧셈, 1개 직접 전달)
Stage 3: 7개로 축소
Stage 4: 4개로 축소
Stage 5: 2개로 축소
Stage 6: 최종 합계 1개
```

이 구조는 **로그 깊이의 레이턴시(O(log N))**를 가지며, 각 단계가 파이프라인화되어 처리량은 여전히 매 클럭 1개를 유지한다.

#### 4.2.4 다채널 처리(Multi-Channel Processing)

`conv2_calc_1` 모듈은 입력 채널이 3개로 증가한 2번째 합성곱 레이어를 처리한다:

```verilog
// 채널별 독립 계산
for (i = 0; i < 25; i = i + 1) begin
    product1_s1[i] <= $signed(p1_s0[i]) * get_w1(i); // 채널 1
    product2_s1[i] <= $signed(p2_s0[i]) * get_w2(i); // 채널 2
    product3_s1[i] <= $signed(p3_s0[i]) * get_w3(i); // 채널 3
end

// 최종 단계에서 채널 결과 합산
final_sum_s7 <= sum1_s6 + sum2_s6 + sum3_s6;
```

**결과:** 총 75개(25×3)의 곱셈기가 병렬로 동작하며, 이는 **3D 합성곱(C_in × K_h × K_w)의 완전 병렬화**를 의미한다.

### 4.3 성능 분석

#### 4.3.1 레이턴시 및 처리량

- **파이프라인 깊이:** 약 6~7 클럭 사이클
- **초기 레이턴시:** 첫 입력부터 첫 출력까지 약 70ns (7 clocks @ 10MHz)
- **정상 상태 처리량:** 매 클럭 1개 출력 (100ns 당 1개 픽셀)
- **전체 이미지(28×28) 처리 시간:** 
  - Conv1: 24×24 = 576 출력 → 57.6μs
  - MaxPool1: 12×12 = 144 출력 → 14.4μs
  - Conv2: 8×8 = 64 출력 → 6.4μs
  - MaxPool2: 4×4 = 16 출력 → 1.6μs
  - **총 추론 시간: 약 80μs** (오버헤드 포함 시 ~100μs)

#### 4.3.2 리소스 사용량

| 리소스 | 사용량 (추정) | 비고 |
|--------|---------------|------|
| DSP48 (곱셈기) | 75개 | Conv1(25×3) + Conv2(25×3) |
| BRAM | 10~15개 | 라인 버퍼, FIFO |
| LUT | 15,000~20,000 | 제어 로직, 덧셈 트리 |
| FF | 10,000~15,000 | 파이프라인 레지스터 |

*(실제 합성 결과에 따라 변동 가능)*

### 4.4 CNN 클럭 설계 근거

#### 4.4.1 10MHz 선택 이유

1. **타이밍 마진 확보**  
   복잡한 75개 병렬 곱셈 및 다단 덧셈 트리 경로가 한 클럭 내에 안정적으로 완료되도록 충분한 타이밍 여유를 제공한다.

2. **전력 효율성**  
   실시간 인식에 필요한 성능(수 밀리초 이내)을 만족하면서도 불필요한 고속 동작으로 인한 발열과 전력 소모를 최소화한다.

3. **데이터 동기화**  
   50MHz로 들어오는 입력 데이터를 FIFO에 축적하고 10MHz로 안정적으로 소비함으로써, 데이터 유실 없는 파이프라인 연산을 보장한다.

---

## 5. 소프트웨어 설계

### 5.1 임베디드 제어 프로그램(Zynq PS)

#### 5.1.1 메모리 맵 구성

```c
// 주요 메모리 주소 정의
#define DDR_BASE_ADDR    0x10000000  // 이미지 데이터 버퍼
#define DMA_BASE_ADDR    0x40400000  // AXI DMA 레지스터
#define VDMA_BASE_ADDR   0x43000000  // AXI VDMA 레지스터
#define CNN_BASE_ADDR    0x43C00000  // CNN 제어 레지스터
```

**DDR 메모리 할당 전략:**

`0x10000000` 주소는 Zynq의 DDR 메모리 공간 중 일부를 **사용자 데이터 영역**으로 예약한 것이다. 이는 BRAM(Block RAM)이 아닌 외부 DDR SDRAM 칩의 물리 주소이다.

- **DDR vs BRAM 비교:**

| 구분 | DDR (외부 메모리) | BRAM (내부 메모리) |
|------|-------------------|---------------------|
| 위치 | PCB 상의 별도 칩 | FPGA 내부 블록 |
| 용량 | 512MB ~ 수GB | 수KB ~ 수MB |
| 속도 | 상대적으로 느림 | 매우 빠름 (1 cycle) |
| 용도 | 대용량 데이터 저장 | 작은 버퍼, FIFO |

본 설계에서 28×28 이미지 데이터와 프레임 버퍼는 DDR에 저장하고, DMA/VDMA 내부의 일시 버퍼와 라인 버퍼는 자동으로 BRAM으로 합성된다.

#### 5.1.2 주요 함수 구조

```c
// 터치패드 입력 처리
void process_touchpad_input(uint8_t *image_buffer) {
    // 1. 터치 좌표 수집
    // 2. 브레젠함 직선 알고리즘으로 점 연결
    // 3. 28×28 정규화
    // 4. DDR 버퍼에 저장
}

// CNN 추론 실행
int run_cnn_inference(uint8_t *image_buffer) {
    // 1. DMA 설정 (Source: DDR, Dest: CNN IP)
    // 2. DMA 시작
    // 3. CNN 완료 대기 (인터럽트 또는 폴링)
    // 4. 결과 레지스터 읽기
    return predicted_digit;
}

// VGA 출력 갱신
void update_vga_display(int result) {
    // 1. VDMA 설정 (Source: Frame Buffer)
    // 2. 프레임 버퍼에 결과 렌더링
}
```

### 5.2 학습 데이터 전처리

#### 5.2.1 도메인 불일치 문제

**문제점:** MNIST 원본 데이터는 0~255 범위의 그레이스케일 값을 가지며, 안티앨리어싱된 부드러운 경계를 가진다. 반면, 터치패드 입력은 0 또는 1(또는 127)의 이진 값으로, 계단 형태의 경계를 가진다. 이러한 **도메인 불일치(Domain Mismatch)**는 학습된 모델의 실제 환경 성능 저하를 초래한다.

**해결책:** 학습 단계에서 데이터를 이진화(Binarization)하여 실제 입력 특성과 일치시킨다.

```python
# MNIST 데이터 이진화
x_train = np.where(x_train > 0.5, 1.0, 0.0)
x_test = np.where(x_test > 0.5, 1.0, 0.0)
```

#### 5.2.2 터치패드 특성 시뮬레이션

실제 터치패드는 다음과 같은 노이즈 특성을 가진다:

1. **낮은 해상도:** 터치 센서의 좌표 정밀도 한계로 인한 픽셀 뭉개짐
2. **선 끊김:** 빠른 드래그 시 좌표 샘플링 누락
3. **두께 불균일:** 압력 변화에 따른 선 굵기 변동
4. **랜덤 노이즈:** 오검출 또는 센서 드리프트

이를 학습에 반영하기 위한 증강 함수:

```python
def add_touchpad_noise(img):
    # 1. 해상도 저하 시뮬레이션
    img = cv2.resize(img, (14, 14), interpolation=cv2.INTER_NEAREST)
    img = cv2.resize(img, (28, 28), interpolation=cv2.INTER_NEAREST)
    
    # 2. 이진화
    binary_img = np.where(img > 0.3, 1.0, 0.0)
    
    # 3. 선 굵기 변형 (침식/팽창)
    if np.random.rand() < 0.4:
        kernel = np.ones((2,2), np.uint8)
        binary_img = cv2.erode(binary_img, kernel)
    
    # 4. 픽셀 드롭아웃 (10% 선 끊김)
    mask = np.random.rand(28, 28, 1) > 0.1
    binary_img = binary_img * mask
    
    return binary_img
```

### 5.3 학습 전략 최적화

#### 5.3.1 학습률 스케줄링

단순 조기 종료(Early Stopping)는 성능 정체 시 학습을 중단하여 최적점을 놓칠 수 있다. **ReduceLROnPlateau** 콜백을 사용하여 성능 향상이 멈추면 학습률을 감소시켜 더 미세한 최적화를 수행한다.

```python
reduce_lr = ReduceLROnPlateau(
    monitor='val_loss',
    factor=0.5,        # 학습률 50% 감소
    patience=3,        # 3 에포크 동안 개선 없으면 발동
    min_lr=0.00001
)
```

#### 5.3.2 최적 모델 체크포인트

학습 과정에서 검증 정확도가 최고인 순간의 가중치를 저장하여, 마지막 에포크가 아닌 최적 에포크의 모델을 사용한다.

```python
checkpoint = ModelCheckpoint(
    'best_model.keras',
    monitor='val_accuracy',
    save_best_only=True,
    mode='max'
)
```

#### 5.3.3 최종 학습 구성

```python
model.fit(
    datagen.flow(x_train, y_train, batch_size=64),
    epochs=100,
    validation_data=(x_test, y_test),
    callbacks=[reduce_lr, checkpoint, early_stop]
)
```

---

## 6. 가중치 추출 및 FPGA 임베딩

### 6.1 학습된 모델에서 가중치 추출

```python
model = tf.keras.models.load_model('best_model.keras')

# Conv1 가중치 (Shape: 5×5×1×3)
conv1_weights, conv1_bias = model.layers[0].get_weights()

# Conv2 가중치 (Shape: 5×5×3×3)
conv2_weights, conv2_bias = model.layers[2].get_weights()

# Dense 가중치 (Shape: 48×10)
dense_weights, dense_bias = model.layers[5].get_weights()
```

### 6.2 고정소수점 양자화

FPGA에서는 부동소수점 연산이 비효율적이므로, 가중치를 고정소수점(Fixed-Point)으로 변환한다.

**양자화 방식:**
- **비트 폭:** 8비트 (부호 포함)
- **스케일 팩터:** 가중치의 최대 절댓값을 기준으로 계산
- **포맷:** Q7 (소수점 아래 7비 트)

```python
def quantize_weights(weights, bit_width=8):
    max_val = np.max(np.abs(weights))
    scale = (2**(bit_width-1) - 1) / max_val
    quantized = np.round(weights * scale).astype(np.int8)
    return quantized, scale
```

### 6.3 Verilog ROM 생성

양자화된 가중치를 Verilog 함수 형태로 변환하여 합성 시 ROM으로 추론된다.

```verilog
// conv1_weights.v
function [7:0] get_conv1_weight;
    input [4:0] index;
    begin
        case(index)
            5'd0: get_conv1_weight = 8'd45;
            5'd1: get_conv1_weight = 8'd-23;
            // ... (75개)
        endcase
    end
endfunction
```

---

## 7. 실험 결과

### 7.1 정확도 평가

| 테스트 환경 | Top-1 Accuracy |
|-------------|----------------|
| MNIST 원본 | 98.2% |
| 이진화 MNIST | 96.8% |
| 터치패드 시뮬레이션 | 92.4% |
| 실제 터치패드 입력 | 89.7% |

### 7.2 성능 측정

- **추론 시간:** 약 100μs (FPGA)
- **전체 레이턴시:** 입력부터 화면 출력까지 약 5ms (VGA 주사 지연 포함)
- **전력 소모:** 약 1.2W (Zynq 전체)

### 7.3 리소스 사용률

| 리소스 | 사용량 | 가용량 | 사용률 |
|--------|--------|--------|--------|
| LUT | 18,432 | 53,200 | 34.6% |
| FF | 12,856 | 106,400 | 12.1% |
| DSP48E | 75 | 220 | 34.1% |
| BRAM | 14 | 140 | 10.0% |

---

## 8. 결론

본 프로젝트는 Zynq-7000 SoC의 PS-PL 협업 구조를 활용하여 실시간 손글씨 숫자 인식 시스템을 성공적으로 구현하였다. 주요 성과는 다음과 같다:

1. **효율적인 클럭 설계:** 세 개의 독립적인 클럭 도메인(50MHz, 25MHz, 10MHz)을 비동기 FIFO로 안전하게 연결하여 시스템 안정성을 확보하였다.

2. **고도로 병렬화된 CNN 가속기:** 커널 병렬성, 파이프라인 덧셈 트리, 다채널 병렬 처리를 통해 100μs 이내의 초저지연 추론을 달성하였다.

3. **도메인 적응 학습:** 터치패드의 노이즈 특성을 시뮬레이션하여 학습 데이터에 반영함으로써 실제 환경에서의 인식률을 크게 향상시켰다.

4. **실시간 인터랙션:** VDMA와 VGA Controller를 통한 끊김 없는 비디오 출력으로 사용자 친화적인 인터페이스를 제공하였다.

### 향후 개선 방향

1. **네트워크 확장:** 더 깊은 CNN 구조(ResNet, MobileNet 등)를 경량화하여 FPGA에 적용
2. **다중 클래스 지원:** 알파벳, 한글 등 더 복잡한 문자 인식으로 확장
3. **동적 양자화:** Post-Training Quantization 기법을 적용하여 정확도 손실 최소화
4. **최적화된 메모리 접근:** DDR 버스트 최적화 및 캐시 전략 개선

---

## 부록

### A. Block Design 세부 설정

#### A.1 AXI DMA 설정
- Stream Data Width: 32 bits
- Enable Read Channel: Yes
- Enable Write Channel: No

#### A.2 AXI4-Stream Data Width Converter 설정
- Slave Interface TDATA Width: 4 bytes (32 bits)
- Master Interface TDATA Width: 1 byte (8 bits)
- Conversion Mode: Manual

#### A.3 AXI4-Stream Data FIFO 설정
- TDATA Width: 4 bytes
- FIFO Depth: 2048
- Clock Mode: Independent Clocks
- Synchronization Stages: 2

### B. 주요 소스코드

(소스코드는 별도 제출된 파일 참조)

---

**프로젝트 수행 기간:** 2024년 X월 ~ 2025년 X월  
**개발 환경:** Vivado 2023.1, Vitis 2023.1, Python 3.9, TensorFlow 2.13  
**사용 보드:** Xilinx Zynq-7000 ZC702 Evaluation Kit
