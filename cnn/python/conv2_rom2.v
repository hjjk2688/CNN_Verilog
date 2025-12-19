function signed [7:0] get_w1(input [4:0] addr);
    case(addr)
        5'd0: get_w1 = 8'shf2;
        5'd1: get_w1 = 8'shfc;
        5'd2: get_w1 = 8'sh12;
        5'd3: get_w1 = 8'she6;
        5'd4: get_w1 = 8'sh02;
        5'd5: get_w1 = 8'sh2d;
        5'd6: get_w1 = 8'sh19;
        5'd7: get_w1 = 8'sh1c;
        5'd8: get_w1 = 8'sh25;
        5'd9: get_w1 = 8'sh0c;
        5'd10: get_w1 = 8'shf1;
        5'd11: get_w1 = 8'sh1b;
        5'd12: get_w1 = 8'shee;
        5'd13: get_w1 = 8'sh0f;
        5'd14: get_w1 = 8'sh2f;
        5'd15: get_w1 = 8'sheb;
        5'd16: get_w1 = 8'sh33;
        5'd17: get_w1 = 8'sh17;
        5'd18: get_w1 = 8'sh04;
        5'd19: get_w1 = 8'sh27;
        5'd20: get_w1 = 8'sh1d;
        5'd21: get_w1 = 8'sh18;
        5'd22: get_w1 = 8'sh22;
        5'd23: get_w1 = 8'shf2;
        5'd24: get_w1 = 8'sh29;
        default: get_w1 = 8'sh00;
    endcase
endfunction

function signed [7:0] get_w2(input [4:0] addr);
    case(addr)
        5'd0: get_w2 = 8'sh0b;
        5'd1: get_w2 = 8'sh07;
        5'd2: get_w2 = 8'sh46;
        5'd3: get_w2 = 8'sh2a;
        5'd4: get_w2 = 8'sh1f;
        5'd5: get_w2 = 8'shec;
        5'd6: get_w2 = 8'shf9;
        5'd7: get_w2 = 8'shc4;
        5'd8: get_w2 = 8'sh02;
        5'd9: get_w2 = 8'sh01;
        5'd10: get_w2 = 8'shd6;
        5'd11: get_w2 = 8'sh4c;
        5'd12: get_w2 = 8'sh03;
        5'd13: get_w2 = 8'shed;
        5'd14: get_w2 = 8'sh51;
        5'd15: get_w2 = 8'shf9;
        5'd16: get_w2 = 8'shf0;
        5'd17: get_w2 = 8'sh58;
        5'd18: get_w2 = 8'sh14;
        5'd19: get_w2 = 8'shfb;
        5'd20: get_w2 = 8'shde;
        5'd21: get_w2 = 8'sh01;
        5'd22: get_w2 = 8'sh9e;
        5'd23: get_w2 = 8'sh0b;
        5'd24: get_w2 = 8'shdc;
        default: get_w2 = 8'sh00;
    endcase
endfunction

function signed [7:0] get_w3(input [4:0] addr);
    case(addr)
        5'd0: get_w3 = 8'shbb;
        5'd1: get_w3 = 8'sh2f;
        5'd2: get_w3 = 8'sh04;
        5'd3: get_w3 = 8'shed;
        5'd4: get_w3 = 8'sh65;
        5'd5: get_w3 = 8'she4;
        5'd6: get_w3 = 8'shc2;
        5'd7: get_w3 = 8'sh4b;
        5'd8: get_w3 = 8'shdb;
        5'd9: get_w3 = 8'she3;
        5'd10: get_w3 = 8'sh39;
        5'd11: get_w3 = 8'sh1e;
        5'd12: get_w3 = 8'shaf;
        5'd13: get_w3 = 8'sh11;
        5'd14: get_w3 = 8'shf5;
        5'd15: get_w3 = 8'she1;
        5'd16: get_w3 = 8'sh22;
        5'd17: get_w3 = 8'she7;
        5'd18: get_w3 = 8'sh04;
        5'd19: get_w3 = 8'sh4c;
        5'd20: get_w3 = 8'shde;
        5'd21: get_w3 = 8'shfa;
        5'd22: get_w3 = 8'sh27;
        5'd23: get_w3 = 8'sh01;
        5'd24: get_w3 = 8'sh1b;
        default: get_w3 = 8'sh00;
    endcase
endfunction
