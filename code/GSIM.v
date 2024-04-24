`timescale 1ns/10ps
module GSIM ( clk, reset, in_en, b_in, out_valid, x_out);
input   clk ;
input   reset ;
input   in_en;
output  out_valid;
input signed  [15:0]  b_in;
output  [31:0]  x_out;


parameter ITERATION  = 120;

parameter state_INPUT = 3'd0;
parameter state_INIT  = 3'd1;
parameter state_PE    = 3'd2;
parameter state_UPDATE= 3'd3;
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
reg signed [31:0] b     [0:15];
reg signed [31:0] nxt_b [0:15];
reg [3:0] b_addr, nxt_b_addr;
reg [6:0] iter, nxt_iter;
wire signed [31:0] x_result;
wire PE_valid, PE_en;
// reg signed [3:0] x_tmp [0:15];

//--------------------------------------
// Finite State Machine
//--------------------------------------
always @(*) begin
    case (state)
        state_IDLE  : nxt_state = state_INPUT;
        state_INPUT : nxt_state = (in_en) ? state_INPUT: state_INIT;
        state_INIT  : nxt_state = state_PE;
        state_PE    : nxt_state = (PE_valid)? state_UPDATE: state_PE;
        state_UPDATE: nxt_state = (x_addr == 15)? state_XDONE: state_PE;
        state_XDONE : nxt_state = (iter < ITERATION)? state_PE: state_OUTPUT;
        state_OUTPUT: nxt_state = state_OUTPUT;
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
        nxt_b[b_addr] = {b_in, 16'b0}; //b_in is 16bit integer
        nxt_b_addr = b_addr + 1;
    end
    else if (state == state_UPDATE) begin // shift b values
        nxt_b[15] = b[0];
        for (i = 0;i < 15 ; i = i +1) begin
            nxt_b[i] = b[i+1];
        end
    end
    else begin
        nxt_b_addr = 0;
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
        b_addr <= 0;
    end
    else begin
        for (i = 0;i < 16 ; i = i +1) begin
            b[i] <= nxt_b[i];
        end
        b_addr <= nxt_b_addr;
    end
end
//--------------------------------------
// initialize & update x values
//--------------------------------------
always @(*) begin
    case (state)
        state_INIT: begin // initialize x values = b/20
            for (i = 0;i < 16 ; i = i +1) begin
                nxt_x[i] = b[i];
            end
            
        end
        state_UPDATE:begin // input result of PE to x
            for (i = 0;i < 16 ; i = i +1) begin
                nxt_x[i] = (x_addr == i)? x_result: x[i];
                // $display("x[",i+1,"] = %h", nxt_x[i]);
            end
        end
        state_XDONE: begin
            for (i = 0;i < 16 ; i = i +1) begin
                // $display("x[",i+1,"] = %h",x[i]);
                nxt_x[i] = x[i];
            end
        end
        default: begin
            for (i = 0;i < 16 ; i = i +1) begin
                nxt_x[i] = x[i];
            end
        end
    endcase
end
always @(posedge clk) begin
    // $display("%d", iter);
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
        state_UPDATE: begin // update x_addr
            nxt_x_addr = x_addr + 1;
        end 
        state_XDONE: begin // reset x_addr when one iteration is done
            nxt_x_addr = 0;
        end
        state_OUTPUT: begin // output x_addr for output
            nxt_x_addr = x_addr + 1;
            // for(i=0; i<16; i=i+1) $display("x[",i+1,"] = %h",x[i]);
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
//--------------------------------------
// x1 -\
//      + add1 - mul13 -\
// x2 -/                 \
//                        + add5-\
// x3 -\                 /        \
//      + add2 - mul6  -/          \
// x4 -/                             + add6 - divide20- x_result
// x5 -\                           /
//      + add3 -\                 /
// x6 -/         + add4--------- / 
// b  ----------/
//--------------------------------------
assign x1 = (x_addr == 0)?      0:
            (x_addr == 15)? x[14]: x[x_addr - 1];
assign x2 = (x_addr == 0)?  x[ 1]:
            (x_addr == 15)?     0: x[x_addr + 1];
assign x3 = (x_addr == 0)?      0:
            (x_addr == 1)?      0:
            (x_addr == 15)? x[13]:
            (x_addr == 14)? x[12]: x[x_addr - 2];
assign x4 = (x_addr == 0)?  x[ 2]:
            (x_addr == 1)?  x[ 3]:
            (x_addr == 15)?     0:
            (x_addr == 14)?     0: x[x_addr + 2];
assign x5 = (x_addr == 0)?      0:
            (x_addr == 1)?      0:
            (x_addr == 2)?      0:
            (x_addr == 15)? x[12]:
            (x_addr == 14)? x[11]:
            (x_addr == 13)? x[10]: x[x_addr - 3];
assign x6 = (x_addr == 0)?  x[ 3]:
            (x_addr == 1)?  x[ 4]:
            (x_addr == 2)?  x[ 5]:
            (x_addr == 15)?     0:
            (x_addr == 14)?     0:
            (x_addr == 13)?     0: x[x_addr + 3];
assign PE_en = (state == state_PE)? 1'b1: 1'b0;
PE PE0( .clk(clk),
        .en(PE_en),
        .reset(reset),
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
        state_INIT: begin
            nxt_iter = 0;
        end
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
// output x values
//--------------------------------------
assign x_out = x[x_addr];
assign out_valid = (state == state_OUTPUT)? 1'b1: 1'b0;
endmodule

module PE ( clk, reset, en, x1, x2, x3, x4, x5, x6, b_in, x_out,  valid);
    input clk, reset, en;
    input signed [31:0] x1, x2, x3, x4, x5, x6;
    input signed [31:0] b_in;
    output signed [31:0] x_out;
    output valid;
    //--------------------------------------
    // reg/net declaration
    //--------------------------------------
    reg [2:0] counter, nxt_counter;
    wire signed [31:0] nxt_divide_20;
    wire signed [36:0] mul_13;
    wire signed [35:0] mul_6;
    wire signed [36:0] add_6;
    reg signed [32:0] add_4, nxt_add_4;
    reg signed [36:0] add_5, nxt_add_5;
    reg signed [32:0] add_1, add_2, add_3;
    reg signed [31:0] divide_20;
    reg signed [32:0] nxt_add_1, nxt_add_2, nxt_add_3;
    //--------------------------------------
    assign x_out = divide_20;
    assign valid = (counter == 3)? 1'b1: 1'b0;
    assign mul_13=  {add_1, 3'b0} + {add_1[32],add_1, 2'b0}+ {{4{add_1[32]}}, add_1};
    assign mul_6 =  {add_2, 2'b0} + {add_2[32], add_2, 1'b0};
    assign add_6 =  add_5 + add_4;
    //--------------------------------------
    // counter
    //--------------------------------------
    always @(*) begin
        if (en) begin
            nxt_counter = counter + 1;
        end
        else begin
            nxt_counter = 0;
        end
    end
    always @(posedge clk) begin
        if (reset) begin
            counter <= 0;
        end
        else begin
            counter <= nxt_counter;
        end
    end

    always @(*) begin
        nxt_add_1 = x1 + x2;
        nxt_add_2 = x3 + x4;
        nxt_add_3 = x5 + x6;
        nxt_add_4 = add_3 + b_in;
        nxt_add_5 = mul_13 - mul_6;
        // nxt_divide_20 = add_6>>6 + add_6>>5 + add_6>>9 + add_6>>10;
        
        /*
        nxt_divide_20 = {{ 5{add_6[32]}}, add_6[32: 5]}+  {{ 6{add_6[32]}}, add_6[32: 6]}+  {{ 9{add_6[32]}}, add_6[32: 9]}+ 
                        {{10{add_6[32]}}, add_6[32:10]}+  {{13{add_6[32]}}, add_6[32:13]}+  {{14{add_6[32]}}, add_6[32:14]}+
                        {{17{add_6[32]}}, add_6[32:17]}+  {{18{add_6[32]}}, add_6[32:18]}+  {{21{add_6[32]}}, add_6[32:21]}+
                        {{22{add_6[32]}}, add_6[32:22]}+  {{25{add_6[32]}}, add_6[32:25]}+  {{26{add_6[32]}}, add_6[32:26]}+
                        {{29{add_6[32]}}, add_6[32:29]}+  {{30{add_6[32]}}, add_6[32:30]};
        */
    end
    divide_by20 div17(.in_div(add_6), .res(nxt_divide_20));
    always @(posedge clk) begin
        case (counter)
            0: begin
                add_1 <= nxt_add_1;
                add_2 <= nxt_add_2;
                add_3 <= nxt_add_3;
            end
            1: begin
                add_4 <= nxt_add_4;
                add_5 <= nxt_add_5;
            end
            2: begin
                divide_20 <= nxt_divide_20;
            end
        endcase
    end
endmodule

module divide_by20(in_div, res);
    input signed [36:0] in_div;
    output signed [31:0] res;
    parameter ACCU = 43;
    wire [ACCU : 0] tmp;
    wire [ACCU - 38:0] res_tmp1;
    wire [4:0] res_tmp2;
    assign tmp = in_div << (ACCU - 37);
    assign {res_tmp2, res, res_tmp1} =  {{ 5{tmp[ACCU]}}, tmp[ACCU: 5]}+  {{ 6{tmp[ACCU]}}, tmp[ACCU: 6]}+  {{ 9{tmp[ACCU]}}, tmp[ACCU: 9]}+ 
                                        {{10{tmp[ACCU]}}, tmp[ACCU:10]}+  {{15{tmp[ACCU]}}, tmp[ACCU:13]}+  {{14{tmp[ACCU]}}, tmp[ACCU:14]}+
                                        {{17{tmp[ACCU]}}, tmp[ACCU:17]}+  {{18{tmp[ACCU]}}, tmp[ACCU:18]}+  {{21{tmp[ACCU]}}, tmp[ACCU:21]}+
                                        {{22{tmp[ACCU]}}, tmp[ACCU:22]}+  {{25{tmp[ACCU]}}, tmp[ACCU:25]}+  {{26{tmp[ACCU]}}, tmp[ACCU:26]}+
                                        {{29{tmp[ACCU]}}, tmp[ACCU:29]}+  {{30{tmp[ACCU]}}, tmp[ACCU:30]}+  {{33{tmp[ACCU]}}, tmp[ACCU:33]}+
                                        {{34{tmp[ACCU]}}, tmp[ACCU:34]};


endmodule