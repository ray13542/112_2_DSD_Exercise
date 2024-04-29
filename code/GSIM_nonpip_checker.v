`timescale 1ns/10ps
module GSIM ( clk, reset, in_en, b_in, out_valid, x_out);
input   clk ;
input   reset ;
input   in_en;
output  out_valid;
input signed  [15:0]  b_in;
output  [31:0]  x_out;


parameter ITERATION  = 80;

parameter state_INPUT = 3'd0;
parameter state_PE    = 3'd2;
parameter state_XDONE = 3'd4;
parameter state_OUTPUT= 3'd5;
parameter state_IDLE  = 3'd6;

//--------------------------------------
// reg/net declaration
//--------------------------------------
reg [2:0] state, nxt_state;
reg signed [31:0] x     [0:15];
reg signed [31:0] nxt_x [0:15];
reg [3:0] x_addr, nxt_x_addr;
integer i;
reg signed [15:0] b     [0:15];
reg signed [15:0] nxt_b [0:15];
reg [6:0] iter, nxt_iter;
wire signed [31:0] x_result;
wire PE_valid;
reg [3:0] check, nxt_check;

//--------------------------------------
// Finite State Machine
//--------------------------------------
always @(*) begin
    case (state)
        state_IDLE  : nxt_state = state_INPUT;
        state_INPUT : nxt_state = (~in_en || x_addr == 4'd15) ? state_PE: state_INPUT;
        state_PE    : nxt_state = (x_addr == 4'd15)? state_XDONE: state_PE;
        state_XDONE : nxt_state = (iter >= ITERATION || check >= 4'd12)? state_OUTPUT: state_PE;
        state_OUTPUT: nxt_state = state_OUTPUT;
        default     : nxt_state = state;
    endcase
end
always @(posedge clk) begin
    if(reset)
        state <= state_IDLE;
    else
        state <= nxt_state;
end
//--------------------------------------
// Input b values
//--------------------------------------

always @(*) begin
    if (in_en) begin
        for (i = 0;i < 16 ; i = i +1) begin
                nxt_b[i] = (i == x_addr)? b_in: b[i];
            end
    end
    else if (state == state_PE)begin
            nxt_b[15] = b[0];
            for (i = 0;i < 15 ; i = i +1) begin
                nxt_b[i] = b[i+1];
            end
    end
    else begin
        for (i = 0;i < 16 ; i = i +1) begin
            nxt_b[i] = b[i];
        end
    end
end
always @(posedge clk) begin
    if (reset) begin
        for (i = 0;i < 16 ; i = i +1) begin
            b[i] <= 0;
        end
    end
    else begin
        for (i = 0;i < 16 ; i = i +1) begin
            b[i] <= nxt_b[i];
        end
    end
end
//--------------------------------------
// initialize & update x values
//--------------------------------------
always @(*) begin
    if (in_en) begin
        for (i = 0;i < 16 ; i = i +1) begin
                nxt_x[i] = (i == x_addr)? {b_in, 16'b0}: x[i];
            end
    end
    else begin
        case (state)
            state_PE: begin
                nxt_x[15] = x_result;
                for (i = 0;i < 15 ; i = i +1) begin
                    nxt_x[i] = x[i+1'b1];
                end
            end
            state_OUTPUT: begin
                nxt_x[15] = x[0];
                for (i = 0;i < 15 ; i = i +1) begin
                    nxt_x[i] = x[i+1'b1];
                end
            end
            default: begin
                for (i = 0;i < 16 ; i = i +1) begin
                    nxt_x[i] = x[i];
                end
            end
        endcase
    end
end
always @(posedge clk) begin
    if (reset) begin
        for (i =0 ; i < 16; i = i + 1) begin
            x[i] <= 0;
        end
    end
    else begin
        for (i =0 ; i < 16; i = i + 1) begin
            x[i] <= nxt_x[i];
        end
    end
end
//--------------------------------------
// Address of x
//--------------------------------------
always @(*) begin
    case (state)
        state_INPUT: begin 
            nxt_x_addr = x_addr + 1'b1;
        end
        state_PE: begin // update x_addr
            nxt_x_addr = x_addr + 1'b1;
        end 
        state_XDONE: begin // reset x_addr when one iteration is done
            nxt_x_addr = 0;
        end
        state_OUTPUT: begin // output x_addr for output
            nxt_x_addr = x_addr + 1'b1;
        end
        default: nxt_x_addr = x_addr;
    endcase
end
always @(posedge clk) begin
    if (reset) begin
        x_addr <= 0;
    end
    else begin
        x_addr <= nxt_x_addr;
    end
end
//--------------------------------------
// Processing x values
//--------------------------------------
wire signed [31:0] x1, x2, x3, x4, x5, x6;
assign x1 = (x_addr < 5'd1 ) ? 32'b0: x[15];
assign x2 = (x_addr > 5'd14) ? 32'b0: x[ 1];
assign x3 = (x_addr < 5'd2 ) ? 32'b0: x[14];
assign x4 = (x_addr > 5'd13) ? 32'b0: x[ 2];
assign x5 = (x_addr < 5'd3 ) ? 32'b0: x[13];
assign x6 = (x_addr > 5'd12) ? 32'b0: x[ 3];
PE PE0( 
        .x1(x1), .x2(x2), .x3(x3), .x4(x4), .x5(x5), .x6(x6),
        .b_in(b[0]),
        .x_out(x_result),
        .valid(PE_valid)
);
//--------------------------------------
// iterate counter
//--------------------------------------
always @(*) begin
    case (state)
        state_XDONE: begin // increase iteration counter
            nxt_iter = iter + 1;
        end
        default: nxt_iter = iter;
    endcase
end
always @(posedge clk) begin
    if (reset) begin
        iter <= 0;
    end
    else begin
        iter <= nxt_iter;
    end
end
//--------------------------------------
// check error
//--------------------------------------
always @(*) begin
    if (state == state_PE && PE_valid) begin
        nxt_check = (x_result == x[0]) ? check + 1'b1: check;
    end
    else begin
        nxt_check = 0;
    end
end
always @(posedge clk) begin
    if (reset) begin
        check <= 0;
    end
    else begin
        check <= nxt_check;
    end
end
//--------------------------------------
// output x values
//--------------------------------------
assign x_out = x[0];
assign out_valid = (state == state_OUTPUT)? 1'b1: 1'b0;
endmodule

module PE (x1, x2, x3, x4, x5, x6, b_in, x_out, valid);
    input signed [31:0] x1, x2, x3, x4, x5, x6;
    input signed [15:0] b_in;
    output signed [31:0] x_out;
    output valid;
    //--------------------------------------
    // reg/net declaration
    //--------------------------------------
    wire signed [31:0] divide_20;
    wire signed [36:0] mul_13;
    wire signed [35:0] mul_6;
    wire signed [36:0] add_6;
    wire signed [36:0] add_5;
    wire signed [32:0] add_1, add_2, add_3;
    //--------------------------------------
    assign valid = 1'b1;
    assign add_1 = x2 + x1;
    assign add_2 = x4 + x3;
    assign add_3 = x5 + x6 + $signed({b_in, 16'b0});
    assign add_5 = mul_13 - mul_6;   
    assign mul_13=  {add_1, 3'b0} + {add_1[32],add_1, 2'b0}+ {{4{add_1[32]}}, add_1};
    assign mul_6 =  {add_2, 2'b0} + {add_2[32], add_2, 1'b0};
    assign add_6 =  add_5 + add_3;
    divide_by20 div17(.in_div(add_6), .res(x_out));
endmodule

module divide_by20(in_div, res);
    input signed [36:0] in_div;
    output signed [31:0] res;
    parameter ACCU = 41;
    wire [ACCU : 0] tmp;
    wire [ACCU - 37:0] res_tmp1;
    wire [4:0] res_tmp2;
    assign tmp = in_div << (ACCU - 36); 
    assign {res_tmp2, res, res_tmp1} =  {{ 5{tmp[ACCU]}}, tmp[ACCU: 5]}+  {{ 6{tmp[ACCU]}}, tmp[ACCU: 6]}+  {{ 9{tmp[ACCU]}}, tmp[ACCU: 9]}+ 
                                        {{10{tmp[ACCU]}}, tmp[ACCU:10]}+  {{13{tmp[ACCU]}}, tmp[ACCU:13]}+  {{14{tmp[ACCU]}}, tmp[ACCU:14]}+
                                        {{17{tmp[ACCU]}}, tmp[ACCU:17]}+  {{18{tmp[ACCU]}}, tmp[ACCU:18]}+  {{21{tmp[ACCU]}}, tmp[ACCU:21]}+
                                        {{22{tmp[ACCU]}}, tmp[ACCU:22]}+  {{25{tmp[ACCU]}}, tmp[ACCU:25]}+  {{26{tmp[ACCU]}}, tmp[ACCU:26]}+
                                        {{29{tmp[ACCU]}}, tmp[ACCU:29]}+  {{30{tmp[ACCU]}}, tmp[ACCU:30]}+  {{33{tmp[ACCU]}}, tmp[ACCU:33]}+
                                        {{34{tmp[ACCU]}}, tmp[ACCU:34]};
endmodule
// module divide_by20(in_div, res);
//     input signed [36:0] in_div;
//     output signed [31:0] res;
//     parameter ACCU = 41; //41 is the minimum ACCU that can pass A
//     wire signed [ACCU : 0] tmp;
//     wire signed [ACCU : 0] tmp0 [0:7];
//     wire signed [ACCU : 0] tmp1 [0:3];
//     wire signed [ACCU : 0] tmp2 [0:1];
//     wire signed [ACCU : 0] tmp3;
//     assign tmp = in_div <<< 5; //AACU - 36
    
//     assign tmp0[0] = {{ 5{tmp[ACCU]}}, tmp[ACCU: 5]}+  {{ 6{tmp[ACCU]}}, tmp[ACCU: 6]};
//     assign tmp0[1] = {{ 9{tmp[ACCU]}}, tmp[ACCU: 9]}+  {{10{tmp[ACCU]}}, tmp[ACCU:10]};
//     assign tmp0[2] = {{13{tmp[ACCU]}}, tmp[ACCU:13]}+  {{14{tmp[ACCU]}}, tmp[ACCU:14]};
//     assign tmp0[3] = {{17{tmp[ACCU]}}, tmp[ACCU:17]}+  {{18{tmp[ACCU]}}, tmp[ACCU:18]};
//     assign tmp0[4] = {{21{tmp[ACCU]}}, tmp[ACCU:21]}+  {{22{tmp[ACCU]}}, tmp[ACCU:22]};
//     assign tmp0[5] = {{25{tmp[ACCU]}}, tmp[ACCU:25]}+  {{26{tmp[ACCU]}}, tmp[ACCU:26]};
//     assign tmp0[6] = {{29{tmp[ACCU]}}, tmp[ACCU:29]}+  {{30{tmp[ACCU]}}, tmp[ACCU:30]};
//     assign tmp0[7] = {{33{tmp[ACCU]}}, tmp[ACCU:33]}+  {{34{tmp[ACCU]}}, tmp[ACCU:34]};

//     assign tmp1[0] = tmp0[0] + tmp0[1];
//     assign tmp1[1] = tmp0[2] + tmp0[3];
//     assign tmp1[2] = tmp0[4] + tmp0[5];
//     assign tmp1[3] = tmp0[6] + tmp0[7];

//     assign tmp2[0] = tmp1[0] + tmp1[1];
//     assign tmp2[1] = tmp1[2] + tmp1[3];

//     assign tmp3 = tmp2[0] + tmp2[1];
//     assign res = tmp3[36:5];//ACCU-5:ACCU-36
// endmodule
//0.0000110011001100110011001100110011
// module divide_by20 (in_div, res);
//     input signed [36:0] in_div;
//     output signed [31:0] res;
//     wire signed [32:0] zero_05;
//     wire signed [69:0] tmp;
//     assign zero_05 = 33'b000011001100110011001100110011001; //This is 0.05 in fixed point
//     assign tmp = in_div * zero_05;
//     assign res = tmp[64:33];
// endmodule