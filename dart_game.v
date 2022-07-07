`timescale 1ns/1ps

module top(clk, master, slave, led, an, seg, reset, switch, resume);
    input clk, reset, switch, resume;
    input [6:0] slave;
    output reg [5:0] led;
    output reg[3:0] an;
    output reg[7:0] seg;
    output [9:0] master;


    wire rst_db, rst_op, switch_db, switch_op, resume_db, resume_op;
    wire clk17, clk22;
    wire [9:0] player0_score, player1_score;
    wire [5:0] led_tmp; //[5:3] for player1, [2:0] for player0
    wire [23:0] out_0, out_1; // connect segmentDisplay

    reg [1:0]count;
    reg player; // player0 and player1


    clk_div #(.n(2**17-1)) clk_17 (clk, rst_op, clk17);
    clk_div #(.n(2**22-1)) clk_22 (clk, rst_op, clk22);

    debounce rstdb(clk, clk17, reset, rst_db);
    onepulse rstop(clk, clk22, rst_db, rst_op);
    debounce switchdb(clk, clk17, switch, switch_db);
    onepulse switchop(clk, clk22, switch_db, switch_op);
    debounce resumedb(clk, clk17, resume, resume_db);
    onepulse resumeop(clk, clk22, resume_db, resume_op);

    dartboard player_0( .clk(clk), .clk_board(clk22), .reset(rst_op), .switch(switch_op), .resume(resume_op), .slave(slave), .player(player),
                            .player_score(player0_score), .remain_times(led_tmp[2:0]) );

    dartboard player_1( .clk(clk), .clk_board(clk22), .reset(rst_op), .switch(switch_op), .resume(resume_op), .slave(slave), .player(~player),
                            .player_score(player1_score), .remain_times(led_tmp[5:3]) );

    segmentDisplay dis_0(.score(player0_score), .out(out_0));
    segmentDisplay dis_1(.score(player1_score), .out(out_1)); 

    assign master = 10'b0;

    always@(posedge clk) begin
        if(clk22) begin
            if(rst_op) begin
                player <= 1'b1;
            end
            else begin
                if(switch_op) player <= ~player;
                else    player <= player;
            end
        end
    end

    always@(*) begin
        if(player) begin
            led[2:0] = led_tmp[2:0];
            led[5:3] = 3'b000;
        end
        else begin
            led[2:0] = 3'b000;
            led[5:3] = led_tmp[5:3];
        end
    end


    always @(posedge clk) begin
        if(clk17) begin
            if(rst_op) begin
                count <= 2'b0;
            end
            else begin
                count <= count+1'b1;
            end
        end
        else begin
        end
    end
    always @(*)begin
        if(player) begin
            case(count)
                2'b00:begin
                    seg = (player0_score==10'd0)? 8'b11110101 : out_0[7:0]; //r
                    an = 4'b1110;
                end
                2'b01:begin
                    if(player0_score<10'd10 && player0_score>10'd0) seg = 8'b11111111;
                    else if (player0_score==8'd0) seg = 8'b11110011; //l
                    else seg = out_0[15:8];
                    an = 4'b1101;
                end
                2'b10:begin
                    seg = (player0_score==10'd0)? 8'b11100101 : out_0[23:16]; //c
                    an = 4'b1011;
                end
                2'b11:begin
                    seg = 8'b11111111;
                    an = 4'b0111;
                end
                default:begin
                    seg = 8'b11111111;
                    an = 4'b1111;
                end
            endcase
        end
        else begin
            case(count)
                2'b00:begin
                    seg = (player1_score==10'd0)? 8'b11110101 : out_1[7:0];
                    an = 4'b1110;
                end
                2'b01:begin
                    if(player1_score<10'd10 && player1_score>10'd0) seg = 8'b11111111;
                    else if (player1_score==10'd0) seg = 8'b11110011;
                    else seg = out_1[15:8];
                    an = 4'b1101;
                end
                2'b10:begin
                    seg = (player1_score==10'd0)? 8'b11100101 : out_1[23:16];
                    an = 4'b1011;
                end
                2'b11:begin
                    seg = 8'b11111111;
                    an = 4'b0111;
                end
                default:begin
                    seg = 8'b11111111;
                    an = 4'b1111;
                end
            endcase
        end
    end

endmodule


module segmentDisplay(score, out);
    input [9:0] score;
    output [23:0] out;

    wire [3:0] num_hun,num_ten,num_one;
    reg [7:0] hun, ten, one;

    assign num_hun = score/100;
    assign num_ten = score/10%10;
    assign num_one = score%10;
    assign out = {hun, ten, one};

    always @(*) begin
        case (num_hun)
            4'd0 : hun = 8'b11111111;	
            4'd1 : hun = 8'b10011111;                                                   
            4'd2 : hun = 8'b00100101;                                                   
            4'd3 : hun = 8'b00001101;                                                
            4'd4 : hun = 8'b10011001;                                                  
            4'd5 : hun = 8'b01001001; 
            4'd11: hun = 8'b11100101;                                                 
            default : hun = 8'b11111111;
        endcase
    end

    always @(*) begin
        case (num_ten)
            4'd0 : ten = 8'b00000011;	
            4'd1 : ten = 8'b10011111;                                                   
            4'd2 : ten = 8'b00100101;                                                   
            4'd3 : ten = 8'b00001101;                                                
            4'd4 : ten = 8'b10011001;                                                  
            4'd5 : ten = 8'b01001001;                                                  
            4'd6 : ten = 8'b01000001;   
            4'd7 : ten = 8'b00011111;   
            4'd8 : ten = 8'b00000001;   
            4'd9 : ten = 8'b00001001;
            4'd11: ten = 8'b11110011;
//            10 : ten = 8'b00000011;
            default : ten = 8'b00000011;
        endcase
    end
    always @(*) begin
        case (num_one)
            4'd0 : one = 8'b00000011;	
            4'd1 : one = 8'b10011111;                                                   
            4'd2 : one = 8'b00100101;                                                   
            4'd3 : one = 8'b00001101;                                                
            4'd4 : one = 8'b10011001;                                                  
            4'd5 : one = 8'b01001001;                                                  
            4'd6 : one = 8'b01000001;   
            4'd7 : one = 8'b00011111;   
            4'd8 : one = 8'b00000001;   
            4'd9 : one = 8'b00001001;
            4'd11: one = 8'b11110101;
            default : one = 8'b11111111;
        endcase
    end
endmodule

module dartboard(clk, clk_board, reset, switch, resume, slave, player, player_score, remain_times);
    input clk, clk_board, reset, switch, resume, player;
    input [6:0] slave;
    output reg [9:0] player_score;
    output reg [2:0] remain_times;

    reg [2:0] state, next_state;
    reg [9:0] score, next_score;
    reg [2:0] next_remain;

    parameter WAIT = 3'b000;
    parameter CNT = 3'b001;
    parameter HOLD = 3'b010;
    parameter SWITCH = 3'b011;
    parameter FINISH = 3'b100;

    always@(posedge clk) begin
        if(clk_board) begin
            if(reset) begin
                state <= WAIT;
                player_score <= 10'd101;
                remain_times <= 3'b111;
            end
            else begin
                state <= next_state;
                player_score <= next_score;
                remain_times <= next_remain;
            end
        end
        else begin
        end
    end

    always@(*) begin
        if(player) begin
            case(state)
            WAIT:begin
                next_score = player_score;
                next_remain = remain_times;
                if(slave==7'b1011111)begin//5
                    next_state = CNT;
                    score = 10'd2;
                end
                else if(slave==7'b1111101)begin//1
                    next_state = CNT;
                    score = 10'd2;
                end
                else if(slave==7'b1101111)begin//4
                    next_state = CNT;
                    score = 10'd1;
                end
                else if(slave==7'b1111011)begin//2
                    next_state = CNT;
                    score = 10'd1;
                end
                else if(slave==7'b1110111)begin//3
                    next_state = CNT;
                    score = 10'd10;
                end
                else if(slave==7'b0111111)begin//6
                    next_state = CNT;
                    score = 10'd3;
                end
                else if(slave==7'b1111110)begin//0
                    next_state = CNT;
                    score = 10'd3;
                end 
                else begin
                    next_state = WAIT;
                    score = 10'd0;
                end
            end
            CNT:begin
                next_score = (player_score>=score) ? player_score-score : player_score;
                if((player_score-score)==10'd0)begin
                    next_state = FINISH;
                end
                else begin 
                    if(remain_times==3'b111) begin
                        next_remain = 3'b011;
                        next_state = HOLD;
                    end
                    else if(remain_times==3'b011) begin
                        next_remain = 3'b001;
                        next_state = HOLD;
                    end
                    else if(remain_times==3'b001) begin
                        next_remain = 3'b000;
                        next_state = SWITCH;
                    end
                    else begin
                        next_remain = 3'b000;
                        next_state = HOLD;
                    end
                end
            end
            HOLD:begin
                next_score = player_score;
                next_remain = remain_times;
                next_state = (resume)?WAIT:HOLD;
            end
            SWITCH:begin//next player
                if(switch) begin
                    next_remain = 3'b111;
                    next_score = player_score;
                    next_state = WAIT;
                end else begin
                    next_remain = remain_times;
                    next_score = player_score;
                    next_state = SWITCH;
                end
            end
            FINISH:begin
                if(player_score==10'd0) next_remain = 3'b111;
                else    next_remain = 3'b111;
                next_score = player_score;
                next_state = FINISH;
            end
            default:begin
                next_remain = remain_times;
                next_score = player_score;
                next_state = state;
            end
            endcase
        end
        else begin
            next_remain = remain_times;
            next_score = player_score;
            next_state = state;
        end
    end
endmodule


module clk_div #(parameter n=(10**7-1)) (clk, rst, new_clk);
input clk, rst;
output new_clk;
reg [32-1:0] cnt;
wire [32-1:0] next_cnt;

    always@(posedge clk)begin
        if(rst) begin
            cnt <= 0;
        end
        else begin
            cnt <= next_cnt;
        end
    end

    assign next_cnt = (cnt==n)?0:cnt+1;
    assign new_clk = (cnt==0)?1'b1:1'b0;
endmodule



module debounce (clk, clk_db, btn, btn_debounced);
input clk, clk_db, btn;
output btn_debounced;
reg [2:0] dff;

    always@(posedge clk) begin
        if(clk_db) begin
            dff[2:1] <= dff[1:0];
            dff[0] <= btn;
        end
    end

    assign btn_debounced = (dff==3'b111) ? 1'b1 : 1'b0;


endmodule


module onepulse (clk, clk_op, btn_debounced, btn_onepulse);
input clk, clk_op, btn_debounced;
output reg btn_onepulse;
reg debounced_delay;

    always@(posedge clk) begin
        if(clk_op) begin
            btn_onepulse <= btn_debounced & (!debounced_delay);
            debounced_delay <= btn_debounced;
        end
    end

endmodule