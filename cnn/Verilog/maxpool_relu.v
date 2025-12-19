/*-------------------------------------------------------------------
*  Module: maxpool_relu
*------------------------------------------------------------------*/

module maxpool_relu #(parameter CONV_BIT = 12, HALF_WIDTH = 12, HALF_HEIGHT = 12, HALF_WIDTH_BIT = 4) (
    input clk,
    input rst_n,	// asynchronous reset, active low
    input valid_in,
    input signed [CONV_BIT - 1 : 0] conv_out_1, conv_out_2, conv_out_3,
    output reg [CONV_BIT - 1 : 0] max_value_1, max_value_2, max_value_3,
    output reg valid_out_relu
    );

    reg signed [CONV_BIT - 1:0] buffer1 [0:HALF_WIDTH - 1];
    reg signed [CONV_BIT - 1:0] buffer2 [0:HALF_WIDTH - 1];
    reg signed [CONV_BIT - 1:0] buffer3 [0:HALF_WIDTH - 1];

    reg [HALF_WIDTH_BIT - 1:0] pcount;
    reg state;
    reg flag;

    always @(posedge clk) begin
        if(~rst_n) begin
            valid_out_relu <= 0;
            pcount <= 0;
            state <= 0;
            flag <= 0;
            // 버퍼 초기화 (선택사항이나 권장)
        end else if(valid_in) begin
            // 1. 동작 제어 (flag와 pcount)
            flag <= ~flag;

            // 2. 데이터 처리 로직
            if(state == 0) begin    // 첫 번째 행 (Row 0 or 2...)
                valid_out_relu <= 0;
                if(flag == 0) begin // (0,0) 위치 데이터 저장
                    buffer1[pcount] <= conv_out_1;
                    buffer2[pcount] <= conv_out_2;
                    buffer3[pcount] <= conv_out_3;
                end else begin      // (0,1) 위치 데이터와 비교
                    if(buffer1[pcount] < conv_out_1) buffer1[pcount] <= conv_out_1;
                    if(buffer2[pcount] < conv_out_2) buffer2[pcount] <= conv_out_2;
                    if(buffer3[pcount] < conv_out_3) buffer3[pcount] <= conv_out_3;
                end
            end else begin          // 두 번째 행 (Row 1 or 3...)
                if(flag == 0) begin // (1,0) 위치 데이터와 비교
                    valid_out_relu <= 0;
                    if(buffer1[pcount] < conv_out_1) buffer1[pcount] <= conv_out_1;
                    if(buffer2[pcount] < conv_out_2) buffer2[pcount] <= conv_out_2;
                    if(buffer3[pcount] < conv_out_3) buffer3[pcount] <= conv_out_3;
                end else begin      // (1,1) 위치 데이터와 최종 비교 + ReLU + 출력
                    valid_out_relu <= 1;
                    // ReLU 로직 (중복 생략, 기존 코드와 동일)
                    max_value_1 <= ( (buffer1[pcount] < conv_out_1 ? conv_out_1 : buffer1[pcount]) > 0 ) ? (buffer1[pcount] < conv_out_1 ? conv_out_1 : buffer1[pcount]) : 0;
                    max_value_2 <= ( (buffer2[pcount] < conv_out_2 ? conv_out_2 : buffer2[pcount]) > 0 ) ? (buffer2[pcount] < conv_out_2 ? conv_out_2 : buffer2[pcount]) : 0;
                    max_value_3 <= ( (buffer3[pcount] < conv_out_3 ? conv_out_3 : buffer3[pcount]) > 0 ) ? (buffer3[pcount] < conv_out_3 ? conv_out_3 : buffer3[pcount]) : 0;
                end
            end

            // 3. 카운터 업데이트 (데이터 처리가 결정된 후 마지막에 수행)
            if(flag == 1) begin
                if(pcount == HALF_WIDTH - 1) begin
                    pcount <= 0;
                    state <= ~state;
                end else begin
                    pcount <= pcount + 1;
                end
            end
        end else begin
            // valid_in이 없을 때는 상태를 유지하되 valid_out만 끈다.
            valid_out_relu <= 0;
        end
    end

endmodule
