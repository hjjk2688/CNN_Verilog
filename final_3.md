제공해주신 **새로운 Python 학습 코드(터치패드 노이즈 시뮬레이션)**와 **누락되었던 AI 모델 구조 표**, 그리고 기존의 **`final_1.md`의 체계성**과 **`final_2.md`의 하드웨어 분석**을 모두 통합하여 완벽한 최종 보고서를 작성해 드립니다.

요청하신 모든 규칙(코드 분석 포함, 모델 구조 표 추가, 최신 노이즈 기법 반영)을 적용했습니다.

---

# FPGA 기반 터치패드 연동 실시간 CNN 가속기 최종 프로젝트 보고서

## 1. 서론 (Introduction)

### 1.1 연구 배경 및 목적

최근 인공지능 기술이 엣지(Edge) 디바이스로 확산됨에 따라, 제한된 자원 환경에서 AI 연산을 효율적으로 수행하는 것이 핵심 과제로 부상했습니다. 일반적인 CPU는 순차 처리 방식의 한계로 인해 실시간 AI 추론에 요구되는 높은 성능과 전력 효율을 동시에 만족시키기 어렵습니다. 이에 대한 효과적인 해결책으로, 하드웨어 수준에서 병렬 처리가 가능한 FPGA(Field-Programmable Gate Array)가 주목받고 있습니다.

본 프로젝트는 Zynq-7000 SoC 플랫폼을 활용하여 **터치패드를 통해 입력된 손글씨 데이터를 실시간으로 인식하는 고성능 CNN 가속기를 설계하고 구현**하는 것을 목표로 합니다. 이를 통해 AI 모델링(Python)부터 RTL 설계(Verilog), 임베디드 시스템 통합(C)까지 아우르는 End-to-End 시스템 구축 역량을 확보하고자 합니다.

### 1.2 시스템 개요

시스템은 크게 다음 세 가지 서브시스템으로 구성됩니다:

* **입력 모듈**: 터치패드를 통한 손글씨 입력 및 전처리 (노이즈 보정 포함)
* **연산 모듈**: FPGA(PL)에 구현된 CNN 가속기를 통한 실시간 숫자 인식
* **출력 모듈**: VGA 디스플레이를 통한 인식 결과 및 입력 형상 시각화

---

## 2. 시스템 아키텍처 (System Architecture)

본 시스템은 Zynq SoC의 핵심 특징인 PS(Processing System)와 PL(Programmable Logic)을 활용한 하드웨어/소프트웨어 공동 설계(Co-design)를 기반으로 합니다.

### 2.1 전체 데이터 흐름 및 구성

데이터는 **[입력] - [전송] - [연산] - [출력]**의 파이프라인을 따라 처리됩니다. 각 단계는 AXI(Advanced eXtensible Interface) 프로토콜을 통해 유기적으로 연결되어 고속 데이터 전송을 보장합니다.

1. **입력 (Touchpad)**: 터치패드로부터 수집된 손글씨 좌표 데이터는 PS에서 28x28 이미지로 전처리된 후 DDR 메모리에 저장됩니다.
2. **데이터 전송 (AXI DMA)**: PS의 제어에 따라 AXI DMA가 DDR 메모리에서 이미지 데이터를 읽어 AXI-Stream 프로토콜 기반의 데이터 패킷으로 변환하여 PL 영역으로 고속 전송합니다.
3. **CNN 가속 (FPGA PL)**: PL에 위치한 CNN 가속기 IP는 스트림 데이터를 실시간으로 수신하여 합성곱, 풀링, 완전 연결 등 모든 추론 연산을 하드웨어적으로 처리합니다.
4. **시각화 (VGA IP)**: PS는 추론 결과를 바탕으로 프레임 버퍼를 갱신하고, AXI VDMA가 이를 읽어 VGA 컨트롤러로 전송하여 모니터에 결과를 출력합니다.

### 2.2 AI 모델 아키텍처 (Model Structure)

본 프로젝트에서 하드웨어로 구현한 CNN 모델은 MNIST 데이터셋에 최적화된 경량화 구조를 가집니다. 각 레이어의 입출력 크기와 연산 정보는 아래와 같습니다.

| 단계 | 레이어 (Layer) | 입력 크기 (Input Shape) | 커널/필터 정보 | 출력 크기 (Output Shape) |
| --- | --- | --- | --- | --- |
| **0** | **Input Image** | 28 x 28 x 1 | - | 28 x 28 x 1 |
| **1** | **Conv2D 1** | 28 x 28 x 1 | 5x5 Kernel, 3 Filters, ReLU | 24 x 24 x 3 |
| **2** | **MaxPooling2D 1** | 24 x 24 x 3 | 2x2 Pooling | 12 x 12 x 3 |
| **3** | **Conv2D 2** | 12 x 12 x 3 | 5x5 Kernel, 3 Filters, ReLU | 8 x 8 x 3 |
| **4** | **MaxPooling2D 2** | 8 x 8 x 3 | 2x2 Pooling | 4 x 4 x 3 |
| **5** | **Flatten** | 4 x 4 x 3 | - | 48 |
| **6** | **Dense (FC)** | 48 | 10 Units, Softmax | 10 (Class 0~9) |

---

## 3. 하드웨어 설계 (Hardware Design)

### 3.1 클럭 아키텍처 및 CDC 설계

시스템 성능과 안정성을 위해 3개의 독립적인 클럭 도메인을 구성하였습니다.

| 클럭 도메인 | 주파수 | 적용 모듈 | 설계 근거 |
| --- | --- | --- | --- |
| **시스템 클럭** | 50 MHz | Zynq PS, DMA | DDR 메모리 인터페이스 대역폭 최적화 |
| **VGA 클럭** | 25.175 MHz | VGA Controller | VGA 640×480@60Hz 표준 비디오 타이밍 준수 |
| **CNN 클럭** | 10 MHz | CNN 가속기 | 복잡한 이진 덧셈 트리(Adder Tree) 파이프라인의 타이밍 마진 확보 |

**CDC(Clock Domain Crossing) 처리:** 50MHz 시스템 클럭과 10MHz 가속기 클럭 간의 데이터 전송은 **AXI4-Stream Data FIFO (Independent Clock Mode)**를 사용하여 안전하게 격리 및 동기화하였습니다.

---

## 4. CNN 가속기 상세 설계 (Detailed Design)

본 장에서는 프로젝트의 핵심인 CNN 가속기의 RTL 설계 및 최적화 기법을 상세히 기술합니다. **Verilog 코드를 분석하여 하드웨어 아키텍처가 어떻게 구현되었는지**를 중점적으로 다룹니다.

### 4.1 시스템 인지 양자화: 고정 스케일링 (Fixed Scaling)

입력 데이터가 터치패드 기반의 이진(0 또는 1) 데이터라는 특성을 활용하여, 복잡한 부동소수점 대신 **INT8 고정소수점** 연산을 적용했습니다. 특히 연산 후 스케일 복원(Re-scaling) 과정에서 DSP를 소모하는 나눗셈기 대신 **비트 시프트(Bit-shift)** 연산을 사용하여 하드웨어를 경량화했습니다.

* **설계 논리:** 입력()  가중치() = 출력()  다음 레이어 입력을 위해 로 복원 필요 ().

```verilog
// [코드 분석: conv2_calc_3.txt]
// 나눗셈(/128) 대신 우측 시프트(>>>7)를 사용하여 DSP 블록을 절약하고 타이밍을 확보함
conv_out_calc <= ($signed(final_sum_s7) >>> 7) + 8'shcf;

```

### 4.2 중앙 제어 로직 (FSM Design)

가속기는 깊은 파이프라인 구조를 가지므로, 외부 데이터 입력이 끊긴 후에도 내부에 남은 데이터를 처리하기 위한 전략이 필요합니다. 이를 위해 **5단계 FSM**을 설계하고, 특히 **`S_PADDING`** 상태를 두어 파이프라인 플러싱(Flushing)을 구현했습니다.

* **상태 정의:** `IDLE` → `RUN_CNN` (데이터 수신) → `PADDING` (플러싱) → `WAIT_DONE` → `RESULT`

```verilog
// [코드 분석: cnn_top.txt]
// S_PADDING 상태일 때 외부 데이터 대신 0(검정색)을 강제 주입하여 잔여 데이터 밀어내기
assign cnn_data_in = (state == S_PADDING) ? 8'd0 : s_axis_tdata;

// 약 2000 클럭 동안 더미 데이터를 밀어넣어(Flushing) 파이프라인 클리어
if (padding_cnt > 2000) state <= S_WAIT_DONE;

```

### 4.3 합성곱 연산 계층: 극단적 병렬화

합성곱 계층은 전체 연산의 병목 구간이므로 **'속도 최우선'** 설계를 적용했습니다.

#### 4.3.1 라인 버퍼 (Line Buffer)

메모리 접근을 최적화하기 위해, 전체 이미지를 저장하는 대신 5개의 행(Row)만 버퍼링하여 5x5 윈도우를 실시간으로 구성합니다. 이를 통해 메모리 사용량을 획기적으로 줄이면서 스트리밍 처리를 가능하게 했습니다.

```verilog
// [코드 분석: conv1_buf.txt]
// 매 클럭마다 데이터가 한 줄씩 위로 이동하며 저장됨 (Data Reuse)
line4_regs[col_cnt] <= line3_regs[col_cnt];
line3_regs[col_cnt] <= line2_regs[col_cnt];
line2_regs[col_cnt] <= line1_regs[col_cnt];
line1_regs[col_cnt] <= data_in;

```

#### 4.3.2 이진 덧셈 트리 (Binary Adder Tree)

25개의 곱셈 결과를 순차적으로 더하는 대신, 토너먼트 방식의 트리 구조로 더하여 Critical Path를 단축시켰습니다. 이는 낮은 클럭 속도에서도 높은 처리량을 보장합니다.

```verilog
// [코드 분석: conv1_calc.txt]
// 25개의 곱셈기가 하드웨어적으로 병렬 생성되어 1클럭에 동시 연산 수행
for (i = 0; i < 25; i = i + 1) begin
    product1_s1[i] <= $signed(p_s0[i]) * get_w1(i);
end
// 이후 Stage 2~6에서 계층적 덧셈 수행 (Pipeline Registers)
for (i=0; i<12; i=i+1) sum1_s2[i] <= product1_s1[2*i] + product1_s1[2*i+1];

```

### 4.4 완전 연결 계층: 자원 효율화

반면, 연산량이 상대적으로 적은 FC 계층은 **'자원 효율 중심'**으로 설계했습니다. 48개의 입력을 처리하기 위해 다수의 곱셈기를 쓰는 대신, **단 1개의 MAC 연산기를 시분할(Time-sharing)로 재사용**하는 FSM 구조를 채택하여 FPGA 리소스를 절약했습니다.

또한 안정성 확보를 위해 데이터 쓰기 로직을 별도의 블록으로 분리하여, 리셋 신호에 의한 메모리 오염을 방지했습니다.

```verilog
// [코드 분석: fully_connected.txt]
// 데이터 저장 로직을 별도 always 블록으로 분리하여 리셋 오동작 방지
always @(posedge clk) begin
    if (valid_in) begin
        // ... (버퍼링 로직)
        input_buffer[buffer_cnt * 3] <= $signed(data_in_1);
    end
end

```

---

## 5. 소프트웨어 설계 및 학습 (Software & Training)

터치패드 입력 데이터는 일반적인 MNIST 이미지와 달리 **노이즈가 없고, 경계가 뚜렷하며(계단 현상), 압력 감지가 불가능한 특성**을 가집니다. 이를 모델 학습 단계에 반영하기 위해 특수한 데이터 증강(Augmentation) 기법을 적용했습니다.

### 5.1 터치패드 패턴 모방 함수 (`add_touchpad_noise`)

학습 데이터에 실제 하드웨어 입력 환경과 유사한 노이즈를 주입하여 모델의 견고성을 높였습니다.

1. **강제 이진화 (Thresholding):**
* 터치패드의 '누름/안 누름' 특성을 반영하여 0.3 이상의 값은 무조건 1.0으로 변환합니다.
* 이를 통해 회색조(Anti-aliasing)를 제거하고 **계단 현상(Aliasing)**을 인위적으로 생성합니다.


```python
binary_img = np.where(img > 0.3, 1.0, 0.0).astype(np.float32)

```


2. **획 두께 변형 (Random Morphology):**
* 손가락의 압력 차이를 시뮬레이션하기 위해 50% 확률로 **팽창(Dilate)** 또는 **침식(Erode)** 연산을 수행합니다.
* 2x2 커널을 사용하여 미세한 두께 변화를 유도합니다.


```python
if np.random.rand() > 0.5:
    binary_img = cv2.dilate(binary_img, kernel, iterations=1) # 꾹 눌렀을 때
else:
    binary_img = cv2.erode(binary_img, kernel, iterations=1)  # 살짝 닿았을 때

```


3. **가장자리 노이즈 (Edge Jitter):**
* 터치 센서의 전기적 노이즈를 반영하기 위해 획의 경계선에 미세한 무작위 노이즈를 추가합니다.


```python
noise = np.random.normal(0, 0.1, binary_img.shape)
noisy_img = binary_img + noise

```



### 5.2 가중치 추출 및 ROM 변환

학습이 완료된 모델(`my_cnn_wild_model_hwc_v2.keras`)의 가중치(Weights)와 편향(Bias)을 추출하고, 이를 `quantize_weights` 함수를 통해 INT8로 양자화한 뒤 Verilog `function` (ROM 형태)으로 변환하여 FPGA 내부에 임베딩하였습니다.

---

## 6. 구현 결과 및 성과 (Results)

### 6.1 성능 분석 (PC vs FPGA)

동일한 알고리즘을 PC(Software)와 FPGA(Hardware)에서 수행했을 때의 추론 속도를 비교하였습니다. 10MHz의 저속 클럭임에도 불구하고 하드웨어 가속기가 더 빠른 성능을 보였습니다.

| 구분 | PC (Software) | FPGA (Hardware) | 비고 |
| --- | --- | --- | --- |
| **플랫폼** | Intel/AMD CPU (GHz급) | Zynq-7000 (10 MHz) |  |
| **연산 방식** | 순차 처리 (Sequential) | **완전 병렬 처리 (Fully Parallel)** |  |
| **총 추론 시간** | 0.5374 ms | **0.2787 ms** | **약 1.93배 가속** |
| **처리 속도** | ~1,860 FPS | **~3,588 FPS** |  |

### 6.2 리소스 사용률

효율적인 아키텍처 설계(고정 스케일링, 시분할 연산)를 통해 Zynq-7000의 제한된 자원 내에서 성공적으로 구현되었습니다.

| 리소스 | 사용량 | 가용량 | 사용률 | 비고 |
| --- | --- | --- | --- | --- |
| **LUT** | 18,432 | 53,200 | 34.6% | 로직 구현 |
| **FF** | 12,856 | 106,400 | 12.1% | 파이프라인 레지스터 |
| **DSP48E** | 75 | 220 | 34.1% | 병렬 곱셈기 |
| **BRAM** | 14 | 140 | 10.0% | 라인 버퍼 및 FIFO |

---

## 7. 결론 (Conclusion)

본 프로젝트는 터치패드 입력부터 CNN 연산, VGA 출력까지 이어지는 **End-to-End 실시간 AI 추론 시스템**을 성공적으로 구현했습니다.

단순히 소프트웨어 알고리즘을 하드웨어로 옮기는 것을 넘어, **데이터 특성(이진화, 노이즈)을 고려한 맞춤형 학습**을 수행하고, 하드웨어 레벨에서는 **파이프라인 플러싱, 이진 덧셈 트리, 비트 시프트 양자화** 등의 최적화 기법을 적용했습니다.

이러한 설계는 10MHz의 저속 클럭으로도 고성능 CPU를 능가하는 효율을 입증하였으며, 향후 엣지 디바이스 환경에서의 고성능 AI 가속기 개발을 위한 견고한 아키텍처 청사진을 제시하였다는 점에서 큰 의의를 가집니다.
