module conv1_calc (
    input                       clk,
    input                       rst_n,
    input                       valid_out_buf,

    input    signed   [7:0]           data_out_0, data_out_1, data_out_2, data_out_3, data_out_4,
                                data_out_5, data_out_6, data_out_7, data_out_8, data_out_9,
                                data_out_10, data_out_11, data_out_12, data_out_13, data_out_14,
                                data_out_15, data_out_16, data_out_17, data_out_18, data_out_19,
                                data_out_20, data_out_21, data_out_22, data_out_23, data_out_24,

    output reg  signed [11:0]          conv_out_1, conv_out_2, conv_out_3,
    output reg                  valid_out_calc
);

    // Pipeline stages:
    // Stage 0: Input data registers
    // Stage 1: Multiplication
    // Stage 2-6: Adder Tree
    localparam P_STAGES = 6;

    // --- Bias Constants (추출된 conv1_b.txt의 16진수 값 입력) ---
    wire signed [7:0] b1 = 8'sh0b; // Bias[0] 값 입력
    wire signed [7:0] b2 = 8'shff; // Bias[1] 값 입력
    wire signed [7:0] b3 = 8'sh02; // Bias[2] 값 입력


    // --- Synthesizable ROMs for weights (implemented as functions) ---
/// --- Conv1 Layer Weights ROM (Generated) ---
function signed [7:0] get_w1(input [4:0] addr);
    case(addr)
        5'd0: get_w1 = 8'sh22;
        5'd1: get_w1 = 8'sh1a;
        5'd2: get_w1 = 8'sh18;
        5'd3: get_w1 = 8'sh09;
        5'd4: get_w1 = 8'sh07;
        5'd5: get_w1 = 8'shfa;
        5'd6: get_w1 = 8'sh11;
        5'd7: get_w1 = 8'sh03;
        5'd8: get_w1 = 8'shf5;
        5'd9: get_w1 = 8'shed;
        5'd10: get_w1 = 8'sha6;
        5'd11: get_w1 = 8'shc3;
        5'd12: get_w1 = 8'shc6;
        5'd13: get_w1 = 8'she9;
        5'd14: get_w1 = 8'shdd;
        5'd15: get_w1 = 8'shc6;
        5'd16: get_w1 = 8'shd2;
        5'd17: get_w1 = 8'shff;
        5'd18: get_w1 = 8'sh0a;
        5'd19: get_w1 = 8'shf6;
        5'd20: get_w1 = 8'sh57;
        5'd21: get_w1 = 8'sh44;
        5'd22: get_w1 = 8'sh11;
        5'd23: get_w1 = 8'sh0d;
        5'd24: get_w1 = 8'sh11;
        default: get_w1 = 8'sh00;
    endcase
endfunction

function signed [7:0] get_w2(input [4:0] addr);
    case(addr)
        5'd0: get_w2 = 8'sh10;
        5'd1: get_w2 = 8'shea;
        5'd2: get_w2 = 8'shde;
        5'd3: get_w2 = 8'she8;
        5'd4: get_w2 = 8'sh17;
        5'd5: get_w2 = 8'sh27;
        5'd6: get_w2 = 8'she6;
        5'd7: get_w2 = 8'shd0;
        5'd8: get_w2 = 8'shdc;
        5'd9: get_w2 = 8'she1;
        5'd10: get_w2 = 8'sh35;
        5'd11: get_w2 = 8'sh42;
        5'd12: get_w2 = 8'sh02;
        5'd13: get_w2 = 8'shf8;
        5'd14: get_w2 = 8'she9;
        5'd15: get_w2 = 8'sh26;
        5'd16: get_w2 = 8'sh26;
        5'd17: get_w2 = 8'sh43;
        5'd18: get_w2 = 8'sh36;
        5'd19: get_w2 = 8'sh2c;
        5'd20: get_w2 = 8'shfe;
        5'd21: get_w2 = 8'sh24;
        5'd22: get_w2 = 8'sh40;
        5'd23: get_w2 = 8'sh36;
        5'd24: get_w2 = 8'sh42;
        default: get_w2 = 8'sh00;
    endcase
endfunction

function signed [7:0] get_w3(input [4:0] addr);
    case(addr)
        5'd0: get_w3 = 8'shcf;
        5'd1: get_w3 = 8'sheb;
        5'd2: get_w3 = 8'shef;
        5'd3: get_w3 = 8'shf6;
        5'd4: get_w3 = 8'sh2b;
        5'd5: get_w3 = 8'she4;
        5'd6: get_w3 = 8'shff;
        5'd7: get_w3 = 8'she4;
        5'd8: get_w3 = 8'sh19;
        5'd9: get_w3 = 8'sh21;
        5'd10: get_w3 = 8'shc9;
        5'd11: get_w3 = 8'shd3;
        5'd12: get_w3 = 8'shf6;
        5'd13: get_w3 = 8'sh14;
        5'd14: get_w3 = 8'sh38;
        5'd15: get_w3 = 8'shbe;
        5'd16: get_w3 = 8'shee;
        5'd17: get_w3 = 8'sh08;
        5'd18: get_w3 = 8'sh26;
        5'd19: get_w3 = 8'sh26;
        5'd20: get_w3 = 8'sheb;
        5'd21: get_w3 = 8'sh05;
        5'd22: get_w3 = 8'sh44;
        5'd23: get_w3 = 8'sh40;
        5'd24: get_w3 = 8'sh35;
        default: get_w3 = 8'sh00;
    endcase
endfunction



    // --- Pipeline Registers ---
    reg [7:0] p_s0 [0:24]; 
    reg signed [15:0] product1_s1[0:24], product2_s1[0:24], product3_s1[0:24];
    reg signed [17:0] sum1_s2[0:12], sum2_s2[0:12], sum3_s2[0:12];
    reg signed [17:0] sum1_s3[0:6],  sum2_s3[0:6],  sum3_s3[0:6];
    reg signed [17:0] sum1_s4[0:3],  sum2_s4[0:3],  sum3_s4[0:3];
    reg signed [17:0] sum1_s5[0:1],  sum2_s5[0:1],  sum3_s5[0:1];
    reg signed [18:0] sum1_s6, sum2_s6, sum3_s6;
    reg [P_STAGES-1:0] valid_pipe;
    
    integer i; // Declare loop variable here
    always @(posedge clk) begin
//        integer i; // Declare loop variable here
        if (!rst_n) begin
            valid_pipe <= 0;
            valid_out_calc <= 0;
            conv_out_1 <= 0;
            conv_out_2 <= 0;
            conv_out_3 <= 0;
            for (i=0; i<25; i=i+1) begin p_s0[i] <= 0; product1_s1[i] <= 0; product2_s1[i] <= 0; product3_s1[i] <= 0; end
            for (i=0; i<13; i=i+1) begin sum1_s2[i] <= 0; sum2_s2[i] <= 0; sum3_s2[i] <= 0; end
            for (i=0; i<7; i=i+1)  begin sum1_s3[i] <= 0; sum2_s3[i] <= 0; sum3_s3[i] <= 0; end
            for (i=0; i<4; i=i+1)  begin sum1_s4[i] <= 0; sum2_s4[i] <= 0; sum3_s4[i] <= 0; end
            for (i=0; i<2; i=i+1)  begin sum1_s5[i] <= 0; sum2_s5[i] <= 0; sum3_s5[i] <= 0; end
            sum1_s6 <= 0; sum2_s6 <= 0; sum3_s6 <= 0;
        end else begin
            // --- Pipeline Control ---
            valid_pipe <= {valid_pipe[P_STAGES-2:0], valid_out_buf};
            valid_out_calc <= valid_pipe[P_STAGES-1];

            // --- Stage 0: Register Inputs ---
            if (valid_out_buf) begin
                p_s0[0] <= data_out_0; p_s0[1] <= data_out_1; p_s0[2] <= data_out_2; p_s0[3] <= data_out_3; p_s0[4] <= data_out_4;
                p_s0[5] <= data_out_5; p_s0[6] <= data_out_6; p_s0[7] <= data_out_7; p_s0[8] <= data_out_8; p_s0[9] <= data_out_9;
                p_s0[10] <= data_out_10; p_s0[11] <= data_out_11; p_s0[12] <= data_out_12; p_s0[13] <= data_out_13; p_s0[14] <= data_out_14;
                p_s0[15] <= data_out_15; p_s0[16] <= data_out_16; p_s0[17] <= data_out_17; p_s0[18] <= data_out_18; p_s0[19] <= data_out_19;
                p_s0[20] <= data_out_20; p_s0[21] <= data_out_21; p_s0[22] <= data_out_22; p_s0[23] <= data_out_23; p_s0[24] <= data_out_24;
            end

            // --- Stage 1: Multiplication ---
            for (i = 0; i < 25; i = i + 1) begin
                product1_s1[i] <= $signed(p_s0[i]) * get_w1(i);
                product2_s1[i] <= $signed(p_s0[i]) * get_w2(i);
                product3_s1[i] <= $signed(p_s0[i]) * get_w3(i);
            end

            // --- Stage 2: Adder Tree Level 1 ---
            for (i = 0; i < 12; i = i + 1) begin
                sum1_s2[i] <= product1_s1[2*i] + product1_s1[2*i+1];
                sum2_s2[i] <= product2_s1[2*i] + product2_s1[2*i+1];
                sum3_s2[i] <= product3_s1[2*i] + product3_s1[2*i+1];
            end
            sum1_s2[12] <= product1_s1[24]; sum2_s2[12] <= product2_s1[24]; sum3_s2[12] <= product3_s1[24];

            // --- Stage 3: Adder Tree Level 2 ---
            for (i = 0; i < 6; i = i + 1) begin
                sum1_s3[i] <= sum1_s2[2*i] + sum1_s2[2*i+1];
                sum2_s3[i] <= sum2_s2[2*i] + sum2_s2[2*i+1];
                sum3_s3[i] <= sum3_s2[2*i] + sum3_s2[2*i+1];
            end
            sum1_s3[6] <= sum1_s2[12]; sum2_s3[6] <= sum2_s2[12]; sum3_s3[6] <= sum3_s2[12];

            // --- Stage 4: Adder Tree Level 3 ---
            sum1_s4[0] <= sum1_s3[0] + sum1_s3[1]; sum1_s4[1] <= sum1_s3[2] + sum1_s3[3]; sum1_s4[2] <= sum1_s3[4] + sum1_s3[5]; sum1_s4[3] <= sum1_s3[6];
            sum2_s4[0] <= sum2_s3[0] + sum2_s3[1]; sum2_s4[1] <= sum2_s3[2] + sum2_s3[3]; sum2_s4[2] <= sum2_s3[4] + sum2_s3[5]; sum2_s4[3] <= sum2_s3[6];
            sum3_s4[0] <= sum3_s3[0] + sum3_s3[1]; sum3_s4[1] <= sum3_s3[2] + sum3_s3[3]; sum3_s4[2] <= sum3_s3[4] + sum3_s3[5]; sum3_s4[3] <= sum3_s3[6];

            // --- Stage 5: Adder Tree Level 4 ---
            sum1_s5[0] <= sum1_s4[0] + sum1_s4[1]; sum1_s5[1] <= sum1_s4[2] + sum1_s4[3];
            sum2_s5[0] <= sum2_s4[0] + sum2_s4[1]; sum2_s5[1] <= sum2_s4[2] + sum2_s4[3];
            sum3_s5[0] <= sum3_s4[0] + sum3_s4[1]; sum3_s5[1] <= sum3_s4[2] + sum3_s4[3];

            // --- Stage 6: Final Addition ---
            sum1_s6 <= sum1_s5[0] + sum1_s5[1];
            sum2_s6 <= sum2_s5[0] + sum2_s5[1];
            sum3_s6 <= sum3_s5[0] + sum3_s5[1];

            // --- Final Output Assignment ---
            if (valid_pipe[P_STAGES-1]) begin
                // 가중치 합산 결과(sum_s6)에 바이어스(b)를 더한 후 127로 나눈 효과(>>> 7)를 줍니다.
                conv_out_1 <= $signed(sum1_s6 + b1) >>> 7;
                conv_out_2 <= $signed(sum2_s6 + b2) >>> 7;
                conv_out_3 <= $signed(sum3_s6 + b3) >>> 7;
            end
        end
    end
endmodule