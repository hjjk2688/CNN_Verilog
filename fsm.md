작성하신 `cnn_top` 모듈의 코드를 분석하여, 최종 프로젝트 보고서에 바로 넣을 수 있는 **[CNN 제어기 설계 및 FSM(Finite State Machine) 동작 분석]** 파트를 작성해 드립니다.

단순히 코드의 나열이 아니라, **왜 이런 상태들이 필요했는지(설계 의도)**를 포함하여 공학적인 완성도를 높였습니다.

---

# 4. CNN 전체 제어 로직 및 FSM 설계 (Global Control Logic)

## 4.1. 제어기 개요

본 프로젝트의 `cnn_top` 모듈은 CNN 가속기의 전체 동작 흐름을 제어하는 마스터 컨트롤러 역할을 수행한다. AXI-Stream 인터페이스를 통한 데이터 수신, 파이프라인 데이터 흐름 제어, 연산 결과 획득 및 성능 측정(Cycle Count)을 관리하기 위해 **5단계의 상태를 갖는 FSM(Finite State Machine)**을 설계하였다.

## 4.2. 상태 천이도 (State Transition Diagram)

*(보고서에 아래의 다이어그램을 참고하여 그림을 그리시면 됩니다)*

1. **IDLE:** 대기 상태 (Reset & Start Switch Check)
2. **RUN_CNN:** 데이터 수신 및 연산 시작 (AXI Handshake)
3. **PADDING:** 파이프라인 플러싱 (Pipeline Flushing via Zero Padding)
4. **WAIT_DONE:** 최종 결과 대기 (Wait for FC Valid)
5. **RESULT:** 결과 출력 및 완료 (Latch Result & Display)

## 4.3. 상태별 상세 동작 정의

FSM은 `rst_n` 신호와 `start_sw` 입력에 의해 초기화되며, 각 상태의 정의와 전이 조건은 다음과 같다.

| 상태 (State) | 동작 설명 (Description) | 전이 조건 (Transition Condition) |
| --- | --- | --- |
| **S_IDLE**<br>

<br>(초기화) | • 시스템 리셋 및 변수 초기화<br>

<br>• `padding_cnt`, `cycle_counter` 0으로 클리어<br>

<br>• `start_sw`가 1이 될 때까지 대기 | `start_sw == 1` <br>

<br> **S_RUN_CNN** |
| **S_RUN_CNN**<br>

<br>(데이터 입력) | • **AXI-Stream 통신 활성화:** `s_axis_tready = 1`<br>

<br>• 외부 데이터(`tdata`)를 첫 번째 Conv 레이어로 전달<br>

<br>• 유효 데이터가 들어올 때 `cnn_pipeline_valid` 활성화 | `s_axis_tlast == 1` (마지막 데이터 수신) <br>

<br> **S_PADDING** |
| **S_PADDING**<br>

<br>(플러싱) | • **Zero-Padding 주입:** 입력 데이터를 강제로 0으로 전환<br>

<br>• 파이프라인에 남아있는 유효 데이터들을 밀어내기 위함<br>

<br>• `padding_cnt`를 증가시키며 2000 사이클 동안 유지 | `padding_cnt > 2000` <br>

<br> **S_WAIT_DONE** |
| **S_WAIT_DONE**<br>

<br>(결과 대기) | • 모든 데이터를 밀어낸 후, FC Layer의 `valid_out` 신호를 최종 확인<br>

<br>• 이미 결과를 캡처했다면 즉시 다음 상태로 이동 | `result_captured_flag == 1` 또는 `fc_valid == 1` <br>

<br> **S_RESULT** |
| **S_RESULT**<br>

<br>(완료) | • 추론 결과(`captured_result`)를 LED에 고정 출력<br>

<br>• `cycle_counter`를 멈추고 `final_time`에 추론 시간 기록<br>

<br>• `done_led` 점등하여 완료 알림 | `start_sw == 0` (스위치 OFF) <br>

<br> **S_IDLE** |

## 4.4. 주요 설계 특징 및 제어 전략

### 4.4.1. 파이프라인 플러싱(Pipeline Flushing) 전략

CNN 가속기는 깊은 파이프라인(Deep Pipeline) 구조를 가지므로, 마지막 픽셀 데이터가 입력된 직후에는 아직 연산 결과가 출력되지 않는다. 이를 해결하기 위해 **S_PADDING** 상태를 도입하였다.

* **Zero Insertion:** `state == S_PADDING`일 때 입력 MUX를 제어하여 외부 데이터 대신 **0(Black Pixel)**을 주입한다.
* **Latency 보장:** 약 2,000 클럭 사이클 동안 더미 데이터를 밀어넣어(Flush), 파이프라인 내부에 남아있는 유효 데이터가 끝까지 연산되어 FC Layer를 통과하도록 보장하였다.

### 4.4.2. 결과 캡처(Result Latching) 메커니즘

FC Layer의 출력 `fc_valid`는 단 1 클럭 사이클만 High 상태를 유지할 수 있다. FSM 상태와 상관없이 정확한 결과를 잡기 위해 **비동기 캡처 로직**을 적용하였다.

* `fc_valid` 신호가 감지되면 즉시 `captured_result` 레지스터에 결과를 저장하고 `result_captured_flag`를 세운다.
* 이를 통해 FSM이 `S_PADDING` 상태에서 카운팅을 하는 도중에 결과가 나오더라도 놓치지 않고 안전하게 획득할 수 있다.

### 4.4.3. 추론 성능 측정 (Inference Timer)

정확한 하드웨어 성능 검증을 위해 **Cycle Counter**를 내장하였다.

* **측정 구간:** `S_IDLE`을 벗어나는 순간부터 `S_RESULT`에 진입하는 순간까지.
* **동작:** `start_sw`가 켜지고 데이터가 입력되기 시작하면 카운터가 증가하며, 결과가 확정되는 순간 카운트 값이 `final_time`에 래치(Latch)된다. 이를 통해 10MHz 클럭 기준 정확한 추론 소요 시간을 측정할 수 있다.

---

### 💡 보고서 작성 팁

1. **다이어그램:** 위 4.2 항목에 PPT나 Visio로 동그라미 5개 그리고 화살표로 연결하는 **상태도(State Diagram)**를 그려 넣으면 완벽합니다. 화살표 위에는 `tlast`, `cnt > 2000` 같은 조건을 적어주세요.
2. **강조점:** 4.4.1의 **"파이프라인 플러싱"** 부분은 하드웨어 설계에서 매우 중요한 테크닉이므로, 이 부분을 구현했다는 것을 강조하면 좋은 평가를 받을 수 있습니다.
