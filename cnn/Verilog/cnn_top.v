`timescale 1ns / 1ps

module cnn_top (
    input wire          clk,
    input wire          rst_n,
    input wire          start,       // 이제 버튼을 한 번만 '딸깍' 누르면 됩니다.
    input wire  [2:0]   sw,          // 노드 확인용 스위치
    output wire [3:0]   result_leds, 
    output reg          done_led,
    output wire         done_led_g,
    output wire         done_led_b
    );
    
    assign done_led_g = 0;
    assign done_led_b = 0;

    // --- 클럭 및 내부 와이어 생략 (이전과 동일) ---
    wire clk_25M;
    clk_wiz_0 CLK_25MHZ_DIVIDE (.clk_out1(clk_25M), .reset(!rst_n), .clk_in1(clk));

    localparam S_IDLE      = 2'd0;
    localparam S_RUN_CNN   = 2'd1;
    localparam S_WAIT_DONE = 2'd2;
    localparam S_RESULT    = 2'd3;

    reg [1:0] state;
    reg [9:0] rom_addr;
    wire [7:0] pixel_data;
    wire conv1_valid, mp1_valid, conv2_valid, fc_valid;
    wire [11:0] conv1_out_1, conv1_out_2, conv1_out_3;
    wire [11:0] mp1_out_1, mp1_out_2, mp1_out_3;
    wire [11:0] conv2_out_1, conv2_out_2, conv2_out_3;
    wire [3:0] fc_debug_out;

    reg cnn_pipeline_valid;
    reg start_d;
    wire start_posedge = start && !start_d;

    // --- 모듈 인스턴스 (이전과 동일) ---
    image_rom u_rom (.addr(rom_addr), .dout(pixel_data));

    conv1_layer u_conv1 (
        .clk(clk_25M), .rst_n(rst_n), .valid_in(cnn_pipeline_valid), .data_in(pixel_data),
        .conv_out_1(conv1_out_1), .conv_out_2(conv1_out_2), .conv_out_3(conv1_out_3),
        .valid_out_conv(conv1_valid)
    );

    maxpool_relu u_mp1 (
        .clk(clk_25M), .rst_n(rst_n), .valid_in(conv1_valid),
        .conv_out_1(conv1_out_1), .conv_out_2(conv1_out_2), .conv_out_3(conv1_out_3),
        .max_value_1(mp1_out_1), .max_value_2(mp1_out_2), .max_value_3(mp1_out_3),
        .valid_out_relu(mp1_valid)
    );

    conv2_layer u_conv2 (
        .clk(clk_25M), .rst_n(rst_n), .valid_in(mp1_valid),
        .max_value_1(mp1_out_1), .max_value_2(mp1_out_2), .max_value_3(mp1_out_3),
        .conv2_out_1(conv2_out_1), .conv2_out_2(conv2_out_2), .conv2_out_3(conv2_out_3),
        .valid_out_conv2(conv2_valid)
    );
    fully_connected u_fc (
        .clk(clk_25M), .rst_n(rst_n), .valid_in(conv2_valid),
        .data_in_1(conv2_out_1), .data_in_2(conv2_out_2), .data_in_3(conv2_out_3),
        .sw(sw), .result_leds(fc_debug_out), .valid_out_fc(fc_valid)
    );

    reg [11:0] wait_cnt;

    // --- 핵심: 상태 머신 로직 수정 ---
    always @(posedge clk_25M or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            rom_addr <= 0;
            cnn_pipeline_valid <= 0;
            start_d <= 0;
            done_led <= 0;
            wait_cnt <= 0;
        end else begin
            start_d <= start;

            case(state)
                S_IDLE: begin
                    done_led <= 0;
                    wait_cnt <= 0;
                    rom_addr <= 0;
                    cnn_pipeline_valid <= 0;
                    if (start_posedge) state <= S_RUN_CNN; // 버튼 누르면 시작
                end

                S_RUN_CNN: begin
                    cnn_pipeline_valid <= 1;
                    if (rom_addr < 10'd783) rom_addr <= rom_addr + 1;
                    else state <= S_WAIT_DONE;
                end

                S_WAIT_DONE: begin
                    if (fc_valid) state <= S_RESULT;
                    else if (wait_cnt < 12'd2000) wait_cnt <= wait_cnt + 1;
                end

                S_RESULT: begin
                    cnn_pipeline_valid <= 0;
                    done_led <= 1; // 연산 종료 알림
                    
                    // [수정] start 버튼을 다시 누르면 IDLE로 가서 재시작하게 만듦
                    // 이제 버튼을 떼고 있어도 S_RESULT 상태에 계속 머무릅니다.
                    if (start_posedge) begin
                        state <= S_IDLE;
                    end
                end
            endcase
        end
    end

    // FC 내부의 멀티플렉서 출력을 그대로 LED에 연결 (실시간 확인용)
    assign result_leds = fc_debug_out;

endmodule