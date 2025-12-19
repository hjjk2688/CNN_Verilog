function signed [7:0] get_w1(input [4:0] addr);
    case(addr)
        5'd0: get_w1 = 8'sh1b;
        5'd1: get_w1 = 8'she9;
        5'd2: get_w1 = 8'shfe;
        5'd3: get_w1 = 8'sh0d;
        5'd4: get_w1 = 8'shf6;
        5'd5: get_w1 = 8'sh0c;
        5'd6: get_w1 = 8'sh0c;
        5'd7: get_w1 = 8'shf6;
        5'd8: get_w1 = 8'sh01;
        5'd9: get_w1 = 8'sh29;
        5'd10: get_w1 = 8'shf8;
        5'd11: get_w1 = 8'sh0f;
        5'd12: get_w1 = 8'sh24;
        5'd13: get_w1 = 8'sh27;
        5'd14: get_w1 = 8'shef;
        5'd15: get_w1 = 8'sh0b;
        5'd16: get_w1 = 8'shf9;
        5'd17: get_w1 = 8'shf7;
        5'd18: get_w1 = 8'sh20;
        5'd19: get_w1 = 8'shf8;
        5'd20: get_w1 = 8'shf9;
        5'd21: get_w1 = 8'sh27;
        5'd22: get_w1 = 8'shef;
        5'd23: get_w1 = 8'shd7;
        5'd24: get_w1 = 8'sh31;
        default: get_w1 = 8'sh00;
    endcase
endfunction

function signed [7:0] get_w2(input [4:0] addr);
    case(addr)
        5'd0: get_w2 = 8'sh19;
        5'd1: get_w2 = 8'shd9;
        5'd2: get_w2 = 8'sh3a;
        5'd3: get_w2 = 8'sh0d;
        5'd4: get_w2 = 8'she7;
        5'd5: get_w2 = 8'shf5;
        5'd6: get_w2 = 8'shfa;
        5'd7: get_w2 = 8'she5;
        5'd8: get_w2 = 8'sh0c;
        5'd9: get_w2 = 8'sh21;
        5'd10: get_w2 = 8'shdf;
        5'd11: get_w2 = 8'sh2b;
        5'd12: get_w2 = 8'sh35;
        5'd13: get_w2 = 8'shf5;
        5'd14: get_w2 = 8'sh33;
        5'd15: get_w2 = 8'sh32;
        5'd16: get_w2 = 8'sh08;
        5'd17: get_w2 = 8'sh29;
        5'd18: get_w2 = 8'sh09;
        5'd19: get_w2 = 8'shff;
        5'd20: get_w2 = 8'shcb;
        5'd21: get_w2 = 8'shfa;
        5'd22: get_w2 = 8'shf2;
        5'd23: get_w2 = 8'sh17;
        5'd24: get_w2 = 8'sh2b;
        default: get_w2 = 8'sh00;
    endcase
endfunction

function signed [7:0] get_w3(input [4:0] addr);
    case(addr)
        5'd0: get_w3 = 8'she5;
        5'd1: get_w3 = 8'sh4d;
        5'd2: get_w3 = 8'sh41;
        5'd3: get_w3 = 8'shf2;
        5'd4: get_w3 = 8'sh66;
        5'd5: get_w3 = 8'sh39;
        5'd6: get_w3 = 8'shee;
        5'd7: get_w3 = 8'sh48;
        5'd8: get_w3 = 8'sh05;
        5'd9: get_w3 = 8'she6;
        5'd10: get_w3 = 8'shbc;
        5'd11: get_w3 = 8'shcd;
        5'd12: get_w3 = 8'she5;
        5'd13: get_w3 = 8'sh1b;
        5'd14: get_w3 = 8'sh0b;
        5'd15: get_w3 = 8'shc3;
        5'd16: get_w3 = 8'sh3a;
        5'd17: get_w3 = 8'sh10;
        5'd18: get_w3 = 8'shc1;
        5'd19: get_w3 = 8'sh55;
        5'd20: get_w3 = 8'sh15;
        5'd21: get_w3 = 8'shdd;
        5'd22: get_w3 = 8'sh31;
        5'd23: get_w3 = 8'sh14;
        5'd24: get_w3 = 8'shd7;
        default: get_w3 = 8'sh00;
    endcase
endfunction
