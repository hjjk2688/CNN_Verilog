function signed [7:0] get_w1(input [4:0] addr);
    case(addr)
        5'd0: get_w1 = 8'sh09;
        5'd1: get_w1 = 8'sh27;
        5'd2: get_w1 = 8'she5;
        5'd3: get_w1 = 8'shf4;
        5'd4: get_w1 = 8'sh04;
        5'd5: get_w1 = 8'she9;
        5'd6: get_w1 = 8'sh10;
        5'd7: get_w1 = 8'shef;
        5'd8: get_w1 = 8'she9;
        5'd9: get_w1 = 8'shef;
        5'd10: get_w1 = 8'she0;
        5'd11: get_w1 = 8'shfb;
        5'd12: get_w1 = 8'shf7;
        5'd13: get_w1 = 8'sh03;
        5'd14: get_w1 = 8'shfc;
        5'd15: get_w1 = 8'sh17;
        5'd16: get_w1 = 8'sh55;
        5'd17: get_w1 = 8'shfe;
        5'd18: get_w1 = 8'sh12;
        5'd19: get_w1 = 8'sh1b;
        5'd20: get_w1 = 8'sh14;
        5'd21: get_w1 = 8'sh12;
        5'd22: get_w1 = 8'sh29;
        5'd23: get_w1 = 8'she3;
        5'd24: get_w1 = 8'sh0b;
        default: get_w1 = 8'sh00;
    endcase
endfunction

function signed [7:0] get_w2(input [4:0] addr);
    case(addr)
        5'd0: get_w2 = 8'shf7;
        5'd1: get_w2 = 8'she9;
        5'd2: get_w2 = 8'sh0b;
        5'd3: get_w2 = 8'sh04;
        5'd4: get_w2 = 8'shfb;
        5'd5: get_w2 = 8'sh12;
        5'd6: get_w2 = 8'sh42;
        5'd7: get_w2 = 8'shf3;
        5'd8: get_w2 = 8'sh10;
        5'd9: get_w2 = 8'sh24;
        5'd10: get_w2 = 8'sh0d;
        5'd11: get_w2 = 8'sh29;
        5'd12: get_w2 = 8'sh04;
        5'd13: get_w2 = 8'sh04;
        5'd14: get_w2 = 8'sh00;
        5'd15: get_w2 = 8'sh08;
        5'd16: get_w2 = 8'shf5;
        5'd17: get_w2 = 8'shf1;
        5'd18: get_w2 = 8'sh08;
        5'd19: get_w2 = 8'sh1c;
        5'd20: get_w2 = 8'shfa;
        5'd21: get_w2 = 8'sh2c;
        5'd22: get_w2 = 8'sh07;
        5'd23: get_w2 = 8'sh03;
        5'd24: get_w2 = 8'sh19;
        default: get_w2 = 8'sh00;
    endcase
endfunction

function signed [7:0] get_w3(input [4:0] addr);
    case(addr)
        5'd0: get_w3 = 8'sh01;
        5'd1: get_w3 = 8'shdd;
        5'd2: get_w3 = 8'shf1;
        5'd3: get_w3 = 8'sh4e;
        5'd4: get_w3 = 8'she1;
        5'd5: get_w3 = 8'shef;
        5'd6: get_w3 = 8'sh1d;
        5'd7: get_w3 = 8'shf7;
        5'd8: get_w3 = 8'shd8;
        5'd9: get_w3 = 8'sh37;
        5'd10: get_w3 = 8'shec;
        5'd11: get_w3 = 8'sh1a;
        5'd12: get_w3 = 8'sh24;
        5'd13: get_w3 = 8'shd3;
        5'd14: get_w3 = 8'sh0c;
        5'd15: get_w3 = 8'sh19;
        5'd16: get_w3 = 8'she2;
        5'd17: get_w3 = 8'sh0d;
        5'd18: get_w3 = 8'sh1e;
        5'd19: get_w3 = 8'sh0c;
        5'd20: get_w3 = 8'she4;
        5'd21: get_w3 = 8'sh45;
        5'd22: get_w3 = 8'shf0;
        5'd23: get_w3 = 8'she9;
        5'd24: get_w3 = 8'sh23;
        default: get_w3 = 8'sh00;
    endcase
endfunction
