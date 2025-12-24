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
Converter 설정창에서 **Master Width를 1로 바꾸는 것**만 잊지 마세요. 그것만 고치면 데이터가 술술 들어갈 겁니다! 성공을 빕니다.
