`timescale 1ns / 1ps

module fully_connected #(
    parameter INPUT_NUM = 48,
    parameter OUTPUT_NUM = 10
    ) (
    input                       clk,
    input                       rst_n,
    input                       valid_in,
    input      signed [11:0]    data_in_1,
    input      signed [11:0]    data_in_2,
    input      signed [11:0]    data_in_3,
    input      [2:0]            sw,           
    output reg [3:0]            result_leds, 
    output reg                  valid_out_fc
    );

    // --- State Machine ---
    localparam S_IDLE      = 3'd0;
    localparam S_BUFFERING = 3'd1;
    localparam S_CALC      = 3'd2;
    localparam S_FIND_MAX  = 3'd3;
    localparam S_DONE      = 3'd4;

    reg [2:0] state;
    reg signed [13:0] input_buffer [0:47];
    reg [5:0] buffer_cnt;
    reg [3:0] neuron_idx;
    reg [5:0] mac_idx;
    reg signed [31:0] mac_sum;
    reg signed [31:0] neuron_outputs [0:9];
    
    reg [3:0] find_max_cnt;
    reg signed [31:0] max_val;
    reg [3:0] final_result;

    // --- Bias & Weight Functions ---
    function signed [7:0] get_bias(input [3:0] addr);
        case(addr)
            4'd0: get_bias = 8'shf9; 4'd1: get_bias = 8'sh30;
            4'd2: get_bias = 8'shf8; 4'd3: get_bias = 8'shdd;
            4'd4: get_bias = 8'sh0b; 4'd5: get_bias = 8'sh0b; 4'd6: get_bias = 8'sh09;
            4'd7: get_bias = 8'sh16; 4'd8: get_bias = 8'shf1; 4'd9: get_bias = 8'shec;
            default: get_bias = 8'sh00;
        endcase
    endfunction

// --- FC Layer Weights ROM (Generated) ---
function signed [7:0] get_weight(input [9:0] addr);
    case(addr)
        10'd0: get_weight = 8'sh2e;
        10'd1: get_weight = 8'she8;
        10'd2: get_weight = 8'sh3e;
        10'd3: get_weight = 8'shdf;
        10'd4: get_weight = 8'sheb;
        10'd5: get_weight = 8'shf6;
        10'd6: get_weight = 8'shf3;
        10'd7: get_weight = 8'sh2c;
        10'd8: get_weight = 8'sh09;
        10'd9: get_weight = 8'shf6;
        10'd10: get_weight = 8'shf2;
        10'd11: get_weight = 8'sh4c;
        10'd12: get_weight = 8'sh2a;
        10'd13: get_weight = 8'shae;
        10'd14: get_weight = 8'shef;
        10'd15: get_weight = 8'shf1;
        10'd16: get_weight = 8'sh0d;
        10'd17: get_weight = 8'shcc;
        10'd18: get_weight = 8'sh10;
        10'd19: get_weight = 8'sh1b;
        10'd20: get_weight = 8'shbb;
        10'd21: get_weight = 8'she7;
        10'd22: get_weight = 8'shd0;
        10'd23: get_weight = 8'sh01;
        10'd24: get_weight = 8'shf0;
        10'd25: get_weight = 8'shc9;
        10'd26: get_weight = 8'sh0a;
        10'd27: get_weight = 8'sh13;
        10'd28: get_weight = 8'sh00;
        10'd29: get_weight = 8'shf6;
        10'd30: get_weight = 8'sh06;
        10'd31: get_weight = 8'sh15;
        10'd32: get_weight = 8'she8;
        10'd33: get_weight = 8'shdf;
        10'd34: get_weight = 8'she8;
        10'd35: get_weight = 8'shd4;
        10'd36: get_weight = 8'shd3;
        10'd37: get_weight = 8'she8;
        10'd38: get_weight = 8'sh06;
        10'd39: get_weight = 8'she4;
        10'd40: get_weight = 8'sh0d;
        10'd41: get_weight = 8'sh08;
        10'd42: get_weight = 8'sh2e;
        10'd43: get_weight = 8'sh06;
        10'd44: get_weight = 8'sh1b;
        10'd45: get_weight = 8'sheb;
        10'd46: get_weight = 8'sh45;
        10'd47: get_weight = 8'shee;
        10'd48: get_weight = 8'shd1;
        10'd49: get_weight = 8'sh39;
        10'd50: get_weight = 8'sh05;
        10'd51: get_weight = 8'shf3;
        10'd52: get_weight = 8'shf0;
        10'd53: get_weight = 8'sh1d;
        10'd54: get_weight = 8'she8;
        10'd55: get_weight = 8'shbf;
        10'd56: get_weight = 8'shb0;
        10'd57: get_weight = 8'sh08;
        10'd58: get_weight = 8'sh14;
        10'd59: get_weight = 8'shb4;
        10'd60: get_weight = 8'sh3a;
        10'd61: get_weight = 8'sh33;
        10'd62: get_weight = 8'sh0d;
        10'd63: get_weight = 8'she3;
        10'd64: get_weight = 8'shf4;
        10'd65: get_weight = 8'shac;
        10'd66: get_weight = 8'sh1e;
        10'd67: get_weight = 8'sh1a;
        10'd68: get_weight = 8'shb1;
        10'd69: get_weight = 8'sh1f;
        10'd70: get_weight = 8'sh3b;
        10'd71: get_weight = 8'shea;
        10'd72: get_weight = 8'sh19;
        10'd73: get_weight = 8'sh27;
        10'd74: get_weight = 8'shdf;
        10'd75: get_weight = 8'shc5;
        10'd76: get_weight = 8'she8;
        10'd77: get_weight = 8'shde;
        10'd78: get_weight = 8'sh0a;
        10'd79: get_weight = 8'shf8;
        10'd80: get_weight = 8'shd9;
        10'd81: get_weight = 8'shf8;
        10'd82: get_weight = 8'sh25;
        10'd83: get_weight = 8'sh16;
        10'd84: get_weight = 8'sh1a;
        10'd85: get_weight = 8'sh1d;
        10'd86: get_weight = 8'sh0a;
        10'd87: get_weight = 8'sh06;
        10'd88: get_weight = 8'sh17;
        10'd89: get_weight = 8'shcc;
        10'd90: get_weight = 8'shf2;
        10'd91: get_weight = 8'sh14;
        10'd92: get_weight = 8'shf5;
        10'd93: get_weight = 8'sh0d;
        10'd94: get_weight = 8'shf4;
        10'd95: get_weight = 8'sh20;
        10'd96: get_weight = 8'shc9;
        10'd97: get_weight = 8'sh37;
        10'd98: get_weight = 8'sh3b;
        10'd99: get_weight = 8'shc8;
        10'd100: get_weight = 8'sh0e;
        10'd101: get_weight = 8'sh19;
        10'd102: get_weight = 8'shff;
        10'd103: get_weight = 8'sh15;
        10'd104: get_weight = 8'shf8;
        10'd105: get_weight = 8'shfa;
        10'd106: get_weight = 8'shcd;
        10'd107: get_weight = 8'shf6;
        10'd108: get_weight = 8'sh07;
        10'd109: get_weight = 8'sh07;
        10'd110: get_weight = 8'shf3;
        10'd111: get_weight = 8'sh00;
        10'd112: get_weight = 8'she8;
        10'd113: get_weight = 8'shf5;
        10'd114: get_weight = 8'sh01;
        10'd115: get_weight = 8'sh09;
        10'd116: get_weight = 8'shd2;
        10'd117: get_weight = 8'sh06;
        10'd118: get_weight = 8'she5;
        10'd119: get_weight = 8'she3;
        10'd120: get_weight = 8'sh4b;
        10'd121: get_weight = 8'shd3;
        10'd122: get_weight = 8'shf0;
        10'd123: get_weight = 8'sh18;
        10'd124: get_weight = 8'shf7;
        10'd125: get_weight = 8'sh00;
        10'd126: get_weight = 8'shf6;
        10'd127: get_weight = 8'sh2c;
        10'd128: get_weight = 8'shfd;
        10'd129: get_weight = 8'sh0a;
        10'd130: get_weight = 8'sh0b;
        10'd131: get_weight = 8'sh2a;
        10'd132: get_weight = 8'she2;
        10'd133: get_weight = 8'sh18;
        10'd134: get_weight = 8'shf1;
        10'd135: get_weight = 8'shd6;
        10'd136: get_weight = 8'sh0a;
        10'd137: get_weight = 8'sh09;
        10'd138: get_weight = 8'sh01;
        10'd139: get_weight = 8'sh09;
        10'd140: get_weight = 8'sh07;
        10'd141: get_weight = 8'shd8;
        10'd142: get_weight = 8'shfc;
        10'd143: get_weight = 8'sh3b;
        10'd144: get_weight = 8'shf3;
        10'd145: get_weight = 8'sh42;
        10'd146: get_weight = 8'sh1a;
        10'd147: get_weight = 8'shf8;
        10'd148: get_weight = 8'sh1d;
        10'd149: get_weight = 8'sh0e;
        10'd150: get_weight = 8'shf3;
        10'd151: get_weight = 8'shd3;
        10'd152: get_weight = 8'sh1f;
        10'd153: get_weight = 8'sh11;
        10'd154: get_weight = 8'she4;
        10'd155: get_weight = 8'shd7;
        10'd156: get_weight = 8'shf8;
        10'd157: get_weight = 8'sh10;
        10'd158: get_weight = 8'sh0a;
        10'd159: get_weight = 8'shf2;
        10'd160: get_weight = 8'shec;
        10'd161: get_weight = 8'shfc;
        10'd162: get_weight = 8'shd7;
        10'd163: get_weight = 8'sh0a;
        10'd164: get_weight = 8'sh25;
        10'd165: get_weight = 8'shea;
        10'd166: get_weight = 8'sh18;
        10'd167: get_weight = 8'sh22;
        10'd168: get_weight = 8'she9;
        10'd169: get_weight = 8'sh0d;
        10'd170: get_weight = 8'sh0f;
        10'd171: get_weight = 8'shc3;
        10'd172: get_weight = 8'shef;
        10'd173: get_weight = 8'sh1c;
        10'd174: get_weight = 8'she0;
        10'd175: get_weight = 8'sh0c;
        10'd176: get_weight = 8'sh1c;
        10'd177: get_weight = 8'sh1a;
        10'd178: get_weight = 8'shc3;
        10'd179: get_weight = 8'she4;
        10'd180: get_weight = 8'sh44;
        10'd181: get_weight = 8'shec;
        10'd182: get_weight = 8'sh24;
        10'd183: get_weight = 8'sh21;
        10'd184: get_weight = 8'she6;
        10'd185: get_weight = 8'sh0b;
        10'd186: get_weight = 8'sh0b;
        10'd187: get_weight = 8'sh0b;
        10'd188: get_weight = 8'sh0c;
        10'd189: get_weight = 8'shfe;
        10'd190: get_weight = 8'she4;
        10'd191: get_weight = 8'shce;
        10'd192: get_weight = 8'sh15;
        10'd193: get_weight = 8'sh9d;
        10'd194: get_weight = 8'she1;
        10'd195: get_weight = 8'sh27;
        10'd196: get_weight = 8'shc4;
        10'd197: get_weight = 8'shd2;
        10'd198: get_weight = 8'shea;
        10'd199: get_weight = 8'shac;
        10'd200: get_weight = 8'shb7;
        10'd201: get_weight = 8'she0;
        10'd202: get_weight = 8'shb4;
        10'd203: get_weight = 8'shd4;
        10'd204: get_weight = 8'she9;
        10'd205: get_weight = 8'shff;
        10'd206: get_weight = 8'shf0;
        10'd207: get_weight = 8'sh03;
        10'd208: get_weight = 8'sh36;
        10'd209: get_weight = 8'sh16;
        10'd210: get_weight = 8'sh08;
        10'd211: get_weight = 8'sh3a;
        10'd212: get_weight = 8'sh06;
        10'd213: get_weight = 8'sh04;
        10'd214: get_weight = 8'shed;
        10'd215: get_weight = 8'sheb;
        10'd216: get_weight = 8'sh1e;
        10'd217: get_weight = 8'sh26;
        10'd218: get_weight = 8'sheb;
        10'd219: get_weight = 8'sh2d;
        10'd220: get_weight = 8'shfe;
        10'd221: get_weight = 8'sh36;
        10'd222: get_weight = 8'sh1d;
        10'd223: get_weight = 8'sh09;
        10'd224: get_weight = 8'sh02;
        10'd225: get_weight = 8'sh2d;
        10'd226: get_weight = 8'sh2b;
        10'd227: get_weight = 8'sh03;
        10'd228: get_weight = 8'shfb;
        10'd229: get_weight = 8'shf4;
        10'd230: get_weight = 8'shee;
        10'd231: get_weight = 8'sh08;
        10'd232: get_weight = 8'shf9;
        10'd233: get_weight = 8'shaf;
        10'd234: get_weight = 8'shfd;
        10'd235: get_weight = 8'shf6;
        10'd236: get_weight = 8'she8;
        10'd237: get_weight = 8'she6;
        10'd238: get_weight = 8'shd9;
        10'd239: get_weight = 8'sh13;
        10'd240: get_weight = 8'sh06;
        10'd241: get_weight = 8'shee;
        10'd242: get_weight = 8'she5;
        10'd243: get_weight = 8'shea;
        10'd244: get_weight = 8'shff;
        10'd245: get_weight = 8'sh20;
        10'd246: get_weight = 8'she2;
        10'd247: get_weight = 8'sh1b;
        10'd248: get_weight = 8'sh28;
        10'd249: get_weight = 8'shc4;
        10'd250: get_weight = 8'sh40;
        10'd251: get_weight = 8'sh22;
        10'd252: get_weight = 8'she5;
        10'd253: get_weight = 8'sh06;
        10'd254: get_weight = 8'sh20;
        10'd255: get_weight = 8'she7;
        10'd256: get_weight = 8'shf5;
        10'd257: get_weight = 8'shfd;
        10'd258: get_weight = 8'sh25;
        10'd259: get_weight = 8'shfa;
        10'd260: get_weight = 8'sh1f;
        10'd261: get_weight = 8'sheb;
        10'd262: get_weight = 8'sh0d;
        10'd263: get_weight = 8'sh32;
        10'd264: get_weight = 8'shc6;
        10'd265: get_weight = 8'sh0d;
        10'd266: get_weight = 8'sh12;
        10'd267: get_weight = 8'shd4;
        10'd268: get_weight = 8'she7;
        10'd269: get_weight = 8'sh21;
        10'd270: get_weight = 8'sh10;
        10'd271: get_weight = 8'she8;
        10'd272: get_weight = 8'she6;
        10'd273: get_weight = 8'shf4;
        10'd274: get_weight = 8'shae;
        10'd275: get_weight = 8'she2;
        10'd276: get_weight = 8'shfa;
        10'd277: get_weight = 8'sh1d;
        10'd278: get_weight = 8'sh0e;
        10'd279: get_weight = 8'sh24;
        10'd280: get_weight = 8'shd7;
        10'd281: get_weight = 8'sh12;
        10'd282: get_weight = 8'shfe;
        10'd283: get_weight = 8'sh07;
        10'd284: get_weight = 8'sh11;
        10'd285: get_weight = 8'shf9;
        10'd286: get_weight = 8'shcd;
        10'd287: get_weight = 8'sh0c;
        10'd288: get_weight = 8'sh05;
        10'd289: get_weight = 8'sh81;
        10'd290: get_weight = 8'shd3;
        10'd291: get_weight = 8'she1;
        10'd292: get_weight = 8'she1;
        10'd293: get_weight = 8'she5;
        10'd294: get_weight = 8'shd0;
        10'd295: get_weight = 8'sh07;
        10'd296: get_weight = 8'shfa;
        10'd297: get_weight = 8'sh80;
        10'd298: get_weight = 8'sh0b;
        10'd299: get_weight = 8'sh3f;
        10'd300: get_weight = 8'sh46;
        10'd301: get_weight = 8'shbd;
        10'd302: get_weight = 8'shbf;
        10'd303: get_weight = 8'sh29;
        10'd304: get_weight = 8'sh11;
        10'd305: get_weight = 8'sh02;
        10'd306: get_weight = 8'sh02;
        10'd307: get_weight = 8'shf2;
        10'd308: get_weight = 8'sh07;
        10'd309: get_weight = 8'sh1b;
        10'd310: get_weight = 8'shf3;
        10'd311: get_weight = 8'sh32;
        10'd312: get_weight = 8'shff;
        10'd313: get_weight = 8'shbe;
        10'd314: get_weight = 8'she7;
        10'd315: get_weight = 8'shf4;
        10'd316: get_weight = 8'she5;
        10'd317: get_weight = 8'sh16;
        10'd318: get_weight = 8'sh19;
        10'd319: get_weight = 8'sh0f;
        10'd320: get_weight = 8'sh0b;
        10'd321: get_weight = 8'shf9;
        10'd322: get_weight = 8'sh00;
        10'd323: get_weight = 8'sh02;
        10'd324: get_weight = 8'sh9a;
        10'd325: get_weight = 8'sh25;
        10'd326: get_weight = 8'shd6;
        10'd327: get_weight = 8'she5;
        10'd328: get_weight = 8'shf4;
        10'd329: get_weight = 8'sh1f;
        10'd330: get_weight = 8'sh22;
        10'd331: get_weight = 8'sh06;
        10'd332: get_weight = 8'sh34;
        10'd333: get_weight = 8'sh23;
        10'd334: get_weight = 8'sh23;
        10'd335: get_weight = 8'shce;
        10'd336: get_weight = 8'shf0;
        10'd337: get_weight = 8'sh49;
        10'd338: get_weight = 8'sh28;
        10'd339: get_weight = 8'sh00;
        10'd340: get_weight = 8'sh05;
        10'd341: get_weight = 8'sh0e;
        10'd342: get_weight = 8'sh35;
        10'd343: get_weight = 8'sh0a;
        10'd344: get_weight = 8'sh2b;
        10'd345: get_weight = 8'sh07;
        10'd346: get_weight = 8'shcd;
        10'd347: get_weight = 8'sh2f;
        10'd348: get_weight = 8'sh11;
        10'd349: get_weight = 8'sh12;
        10'd350: get_weight = 8'sh1b;
        10'd351: get_weight = 8'sh28;
        10'd352: get_weight = 8'sh27;
        10'd353: get_weight = 8'shae;
        10'd354: get_weight = 8'shbb;
        10'd355: get_weight = 8'sh1a;
        10'd356: get_weight = 8'shcb;
        10'd357: get_weight = 8'shd7;
        10'd358: get_weight = 8'shf6;
        10'd359: get_weight = 8'sh0f;
        10'd360: get_weight = 8'sh00;
        10'd361: get_weight = 8'sh06;
        10'd362: get_weight = 8'shf6;
        10'd363: get_weight = 8'sh14;
        10'd364: get_weight = 8'shfd;
        10'd365: get_weight = 8'shee;
        10'd366: get_weight = 8'sh12;
        10'd367: get_weight = 8'shfa;
        10'd368: get_weight = 8'sh19;
        10'd369: get_weight = 8'shf6;
        10'd370: get_weight = 8'sh2e;
        10'd371: get_weight = 8'shf9;
        10'd372: get_weight = 8'shf1;
        10'd373: get_weight = 8'she5;
        10'd374: get_weight = 8'shd4;
        10'd375: get_weight = 8'shf0;
        10'd376: get_weight = 8'shfc;
        10'd377: get_weight = 8'sha5;
        10'd378: get_weight = 8'shf2;
        10'd379: get_weight = 8'shea;
        10'd380: get_weight = 8'shb8;
        10'd381: get_weight = 8'shee;
        10'd382: get_weight = 8'sh07;
        10'd383: get_weight = 8'shbd;
        10'd384: get_weight = 8'sheb;
        10'd385: get_weight = 8'shc0;
        10'd386: get_weight = 8'sh1e;
        10'd387: get_weight = 8'she9;
        10'd388: get_weight = 8'shf2;
        10'd389: get_weight = 8'sh27;
        10'd390: get_weight = 8'shf8;
        10'd391: get_weight = 8'sh29;
        10'd392: get_weight = 8'sh13;
        10'd393: get_weight = 8'shf9;
        10'd394: get_weight = 8'shec;
        10'd395: get_weight = 8'sh03;
        10'd396: get_weight = 8'sh03;
        10'd397: get_weight = 8'sh19;
        10'd398: get_weight = 8'sh11;
        10'd399: get_weight = 8'shf5;
        10'd400: get_weight = 8'shcd;
        10'd401: get_weight = 8'sh0e;
        10'd402: get_weight = 8'sh22;
        10'd403: get_weight = 8'she4;
        10'd404: get_weight = 8'sh12;
        10'd405: get_weight = 8'shed;
        10'd406: get_weight = 8'sh36;
        10'd407: get_weight = 8'sh00;
        10'd408: get_weight = 8'sh45;
        10'd409: get_weight = 8'shb2;
        10'd410: get_weight = 8'she8;
        10'd411: get_weight = 8'sh07;
        10'd412: get_weight = 8'sheb;
        10'd413: get_weight = 8'shf6;
        10'd414: get_weight = 8'she3;
        10'd415: get_weight = 8'sh17;
        10'd416: get_weight = 8'sh08;
        10'd417: get_weight = 8'sh1f;
        10'd418: get_weight = 8'shf9;
        10'd419: get_weight = 8'she0;
        10'd420: get_weight = 8'shc8;
        10'd421: get_weight = 8'sh00;
        10'd422: get_weight = 8'shf1;
        10'd423: get_weight = 8'shfe;
        10'd424: get_weight = 8'she6;
        10'd425: get_weight = 8'sh23;
        10'd426: get_weight = 8'sh04;
        10'd427: get_weight = 8'shed;
        10'd428: get_weight = 8'sh31;
        10'd429: get_weight = 8'shee;
        10'd430: get_weight = 8'shea;
        10'd431: get_weight = 8'sh02;
        10'd432: get_weight = 8'sh24;
        10'd433: get_weight = 8'shc4;
        10'd434: get_weight = 8'sh0f;
        10'd435: get_weight = 8'shf5;
        10'd436: get_weight = 8'sh01;
        10'd437: get_weight = 8'shed;
        10'd438: get_weight = 8'shf7;
        10'd439: get_weight = 8'sh28;
        10'd440: get_weight = 8'sh14;
        10'd441: get_weight = 8'sh3e;
        10'd442: get_weight = 8'shf9;
        10'd443: get_weight = 8'sh0a;
        10'd444: get_weight = 8'she3;
        10'd445: get_weight = 8'shfe;
        10'd446: get_weight = 8'shdd;
        10'd447: get_weight = 8'shf5;
        10'd448: get_weight = 8'sh21;
        10'd449: get_weight = 8'sh3d;
        10'd450: get_weight = 8'shdb;
        10'd451: get_weight = 8'sheb;
        10'd452: get_weight = 8'sh09;
        10'd453: get_weight = 8'sh35;
        10'd454: get_weight = 8'she8;
        10'd455: get_weight = 8'shea;
        10'd456: get_weight = 8'she5;
        10'd457: get_weight = 8'sh28;
        10'd458: get_weight = 8'sh23;
        10'd459: get_weight = 8'shf8;
        10'd460: get_weight = 8'shf8;
        10'd461: get_weight = 8'sh42;
        10'd462: get_weight = 8'sh0d;
        10'd463: get_weight = 8'sh07;
        10'd464: get_weight = 8'shcf;
        10'd465: get_weight = 8'shd2;
        10'd466: get_weight = 8'she5;
        10'd467: get_weight = 8'shba;
        10'd468: get_weight = 8'sh00;
        10'd469: get_weight = 8'shef;
        10'd470: get_weight = 8'shf8;
        10'd471: get_weight = 8'sh09;
        10'd472: get_weight = 8'shfc;
        10'd473: get_weight = 8'shc4;
        10'd474: get_weight = 8'sh1a;
        10'd475: get_weight = 8'shf4;
        10'd476: get_weight = 8'shdc;
        10'd477: get_weight = 8'shc4;
        10'd478: get_weight = 8'she0;
        10'd479: get_weight = 8'sh0e;
        default: get_weight = 8'sh00;
    endcase
endfunction

    // 연산 타이밍과 부호를 맞추기 위한 중간 변수
    wire signed [7:0]  w_data = get_weight(neuron_idx * 48 + mac_idx);
    wire signed [13:0] i_data = input_buffer[mac_idx];
    
    reg signed [7:0] temp_bias;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            buffer_cnt <= 0;
            valid_out_fc <= 0;
            neuron_idx <= 0;
            mac_idx <= 0;
            mac_sum <= 0;
            find_max_cnt <= 0;
            max_val <= 32'sh80000000;
            final_result <= 0;
            result_leds <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    buffer_cnt <= 0;
                    neuron_idx <= 0;
                    mac_idx    <= 0;
                    mac_sum    <= 0;
                    valid_out_fc <= 0;
                    find_max_cnt <= 0;
                    max_val <= 32'sh80000000;
                    if (valid_in) state <= S_BUFFERING;
                end

//                S_BUFFERING: begin
//                    if (valid_in) begin
//                        input_buffer[buffer_cnt]      <= data_in_1;
//                        input_buffer[buffer_cnt + 6'd16] <= data_in_2;
//                        input_buffer[buffer_cnt + 6'd32] <= data_in_3;
//                        if (buffer_cnt == 15) begin
//                            buffer_cnt <= 0;
//                            state <= S_CALC;
//                        end else begin
//                            buffer_cnt <= buffer_cnt + 1;
//                        end
//                    end
//                end
                S_BUFFERING: begin
                    if (valid_in) begin
                        // *** 핵심: 동시에 들어오는 3개 채널을 각각의 영역에 따로 쌓아줍니다 ***
                        // data_in_1 (채널1) -> 0, 1, 2... 15번지
                        // data_in_2 (채널2) -> 16, 17, 18... 31번지
                        // data_in_3 (채널3) -> 32, 33, 34... 47번지
                        
                        input_buffer[buffer_cnt]          <= data_in_1; 
                        input_buffer[buffer_cnt + 6'd16]  <= data_in_2; 
                        input_buffer[buffer_cnt + 6'd32]  <= data_in_3; 
                        
                        if (buffer_cnt == 15) begin
                            buffer_cnt <= 0;
                            state <= S_CALC;
                        end else begin
                            buffer_cnt <= buffer_cnt + 1;
                        end
                    end
                end

           
                S_CALC: begin
                    if (mac_idx < 48) begin
                        // $signed를 붙여서 부호 있는 곱셈임을 컴파일러에게 확실히 알림
                        mac_sum <= mac_sum + ($signed(input_buffer[mac_idx]) * $signed(get_weight(neuron_idx * 48 + mac_idx)));                        
                        mac_idx <= mac_idx + 1;
                    end else begin
                        // 1. 먼저 함수 값을 변수에 할당 (Verilog 표준 방식)
                        temp_bias = get_bias(neuron_idx); 
                        
                        // 2. $signed 키워드를 사용하여 안전하게 더하기
                        // 이렇게 하면 툴이 알아서 32비트로 부호 확장을 해줍니다.
                        neuron_outputs[neuron_idx] <= mac_sum + {{24{temp_bias[7]}}, temp_bias};
                        
                        mac_idx <= 0;
                        mac_sum <= 0;
                        if (neuron_idx == 9) state <= S_FIND_MAX;
                        else neuron_idx <= neuron_idx + 1;
                    end
                end

                S_FIND_MAX: begin
                    if (find_max_cnt < 10) begin
                        if (neuron_outputs[find_max_cnt] > max_val) begin
                            max_val <= neuron_outputs[find_max_cnt];
                            final_result <= find_max_cnt;
                        end
                        find_max_cnt <= find_max_cnt + 1;
                    end else begin
                        state <= S_DONE;
                    end
                end
                
                    S_DONE: begin
                    valid_out_fc <= 1'b1;
                    
                    if (sw == 3'b000) begin
                        result_leds <= final_result; // 최종 예측 값
                    end else if (sw == 3'b111) begin
                        // *** [임시] 스위치 7번을 올리면 9번 노드 상태를 출력 ***
                        result_leds[3] <= neuron_outputs[9][31]; // 9번의 부호
                        result_leds[2] <= (neuron_outputs[9] > 32'sd100 || neuron_outputs[9] < -32'sd100);
                        result_leds[1] <= (neuron_outputs[9] > 32'sd10  || neuron_outputs[9] < -32'sd10);
                        result_leds[0] <= (neuron_outputs[9] != 0);
                    end else begin
                        // 그 외 스위치(1~6)는 그대로 1~6번 노드 출력
                        result_leds[3] <= neuron_outputs[sw][31];
                        result_leds[2] <= (neuron_outputs[sw] > 32'sd100 || neuron_outputs[sw] < -32'sd100);
                        result_leds[1] <= (neuron_outputs[sw] > 32'sd10  || neuron_outputs[sw] < -32'sd10);
                        result_leds[0] <= (neuron_outputs[sw] != 0);
                    end

                    if (valid_in) begin 
                        state <= S_BUFFERING;
                        valid_out_fc <= 0;
                        find_max_cnt <= 0;
                    end
                end
            endcase
        end
    end
endmodule