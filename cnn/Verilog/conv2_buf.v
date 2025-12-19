module conv2_buf #(
    parameter WIDTH     = 12,
    parameter HEIGHT    = 12,
    parameter DATA_BITS = 12
)(
    input                        clk,
    input                        rst_n,
    input                        valid_in,
    input   signed   [DATA_BITS-1:0]   data_in,

    output wire signed [DATA_BITS-1:0] data_out_0, data_out_1, data_out_2, data_out_3, data_out_4,
                                data_out_5, data_out_6, data_out_7, data_out_8, data_out_9,
                                data_out_10, data_out_11, data_out_12, data_out_13, data_out_14,
                                data_out_15, data_out_16, data_out_17, data_out_18, data_out_19,
                                data_out_20, data_out_21, data_out_22, data_out_23, data_out_24,
    output reg                 valid_out_buf 
);

    // --------------------------------------------------
    // Line buffers
    // --------------------------------------------------
    reg [DATA_BITS-1:0] line1_regs [0:WIDTH-1];
    reg [DATA_BITS-1:0] line2_regs [0:WIDTH-1];
    reg [DATA_BITS-1:0] line3_regs [0:WIDTH-1];
    reg [DATA_BITS-1:0] line4_regs [0:WIDTH-1];
    
    // --------------------------------------------------
    // Shift registers for 5x5 window
    // --------------------------------------------------
    reg [DATA_BITS-1:0] s0[0:4], s1[0:4], s2[0:4], s3[0:4], s4[0:4];

    // --------------------------------------------------
    // Counters
    // --------------------------------------------------
    reg [$clog2(WIDTH)-1:0]  col_cnt;
    reg [$clog2(HEIGHT)-1:0] row_cnt;

    // --------------------------------------------------
    // Main Sequential Logic
    // --------------------------------------------------
    integer i;
    always @(posedge clk) begin
        if (!rst_n) begin
            col_cnt <= 0;
            row_cnt <= 0;
            valid_out_buf <= 1'b0;
            for (i = 0; i < 5; i = i + 1) begin
                s0[i] <= 0; s1[i] <= 0; s2[i] <= 0; s3[i] <= 0; s4[i] <= 0;
            end
        end else if (valid_in) begin
            // 1. Line Buffers: Vertical Shift
            line4_regs[col_cnt] <= line3_regs[col_cnt];
            line3_regs[col_cnt] <= line2_regs[col_cnt];
            line2_regs[col_cnt] <= line1_regs[col_cnt];
            line1_regs[col_cnt] <= data_in;

            // 2. Shift Registers: Horizontal Shift
            s4[0] <= line4_regs[col_cnt]; s4[1] <= s4[0]; s4[2] <= s4[1]; s4[3] <= s4[2]; s4[4] <= s4[3];
            s3[0] <= line3_regs[col_cnt]; s3[1] <= s3[0]; s3[2] <= s3[1]; s3[3] <= s3[2]; s3[4] <= s3[3];
            s2[0] <= line2_regs[col_cnt]; s2[1] <= s2[0]; s2[2] <= s2[1]; s2[3] <= s2[2]; s2[4] <= s2[3];
            s1[0] <= line1_regs[col_cnt]; s1[1] <= s1[0]; s1[2] <= s1[1]; s1[3] <= s1[2]; s1[4] <= s1[3];
            s0[0] <= data_in;            s0[1] <= s0[0]; s0[2] <= s0[1]; s0[3] <= s0[2]; s0[4] <= s0[3];
            
            // 3. Counters Update
            if (col_cnt == WIDTH - 1) begin
                col_cnt <= 0;
                if (row_cnt == HEIGHT - 1) begin
                    row_cnt <= 0;
                end else begin
                    row_cnt <= row_cnt + 1'b1;
                end
            end else begin
                col_cnt <= col_cnt + 1'b1;
            end

            // 4. Valid Output Logic: 5x5 window is ready from row 4 onwards
            if (row_cnt >= 4 && col_cnt >= 4) begin
                valid_out_buf <= 1'b1;
            end else begin
                valid_out_buf <= 1'b0;
            end

        end else begin
            // When valid_in is low, hold valid_out_buf low
            valid_out_buf <= 1'b0;
        end
    end

    // --------------------------------------------------
    // Output Window Assignment
    // --------------------------------------------------
    assign {data_out_0,  data_out_1,  data_out_2,  data_out_3,  data_out_4}  = {s4[4],s4[3],s4[2],s4[1],s4[0]};
    assign {data_out_5,  data_out_6,  data_out_7,  data_out_8,  data_out_9}  = {s3[4],s3[3],s3[2],s3[1],s3[0]};
    assign {data_out_10, data_out_11, data_out_12, data_out_13, data_out_14} = {s2[4],s2[3],s2[2],s2[1],s2[0]};
    assign {data_out_15, data_out_16, data_out_17, data_out_18, data_out_19} = {s1[4],s1[3],s1[2],s1[1],s1[0]};
    assign {data_out_20, data_out_21, data_out_22, data_out_23, data_out_24} = {s0[4],s0[3],s0[2],s0[1],s0[0]};

endmodule