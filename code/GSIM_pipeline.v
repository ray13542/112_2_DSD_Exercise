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
// reg [3:0] x_addr, nxt_x_addr;
reg [4:0] counter, nxt_counter;
integer i;
reg signed [31:0] b     [0:15];
reg signed [31:0] nxt_b [0:15];
reg [3:0] b_addr, nxt_b_addr;
reg [6:0] iter, nxt_iter;
wire signed [31:0] x_result;
wire PE_valid, PE_en;

//--------------------------------------
// Finite State Machine
//--------------------------------------
always @(*) begin
    case (state)
        state_IDLE  : nxt_state = state_INPUT;
        state_INPUT : nxt_state = (in_en) ? state_INPUT: state_PE;
        // state_INIT  : nxt_state = state_PE;
        state_PE    : nxt_state = (counter == 5'd17)? state_XDONE: state_PE;
        // state_UPDATE: nxt_state = (x_addr == 15)? state_XDONE: state_PE;
        state_XDONE : nxt_state = (iter < ITERATION)? state_PE: state_OUTPUT;
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
    case (state)
        state_INPUT: nxt_b_addr = b_addr+1; 
        default: nxt_b_addr = 0;
    endcase
end
always @(posedge clk) begin
    if (reset) begin
        b_addr <= 0;
    end
    else begin
        b_addr <= nxt_b_addr;
    end
end

always @(*) begin
    if (in_en) begin
        for (i = 0;i < 16 ; i = i +1) begin
                nxt_b[i] = (i == b_addr)? {b_in, 16'b0}: b[i];
        end
    end
    else if (state == state_PE)begin
            nxt_b[15] = b[0];
            for (i = 0;i < 15 ; i = i +1) begin
                nxt_b[i] = b[i+1];
            end
    end
    else if (state == state_XDONE)begin
            nxt_b[0] = b[14];
            nxt_b[1] = b[15];
            for (i = 2; i < 16 ; i = i +1) begin
                nxt_b[i] = b[i-2];
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
    // case (state)
    //     state_INPUT: begin // initialize x values = b
    //         for (i = 0;i < 16 ; i = i +1) begin
    //             // nxt_x[i] = b[i];
    //             nxt_x[i] = (i == b_addr)? {b_in, 16'b0}: x[i];
    //         end
            
    //     end
    //     state_PE:begin // input result of PE to x
    //         for (i = 0;i < 16 ; i = i +1) begin
    //             nxt_x[i] = (x_addr == i)? x_result: x[i];
    //             // $display("x[",i+1,"] = %h", nxt_x[i]);
    //         end
    //     end
    //     state_XDONE: begin
    //         for (i = 0;i < 16 ; i = i +1) begin
    //             // $display("x[",i+1,"] = %h",x[i]);
    //             nxt_x[i] = x[i];
    //         end
    //     end
    //     default: begin
    //         for (i = 0;i < 16 ; i = i +1) begin
    //             nxt_x[i] = x[i];
    //         end
    //     end
    // endcase
    if (in_en) begin
        for (i = 0;i < 16 ; i = i +1) begin
            nxt_x[i] = (i == b_addr)? {b_in, 16'b0}: x[i];
        end
    end
    else if (state == state_PE)begin
            nxt_x[15] = x[0];
            for (i = 0;i < 15 ; i = i +1) begin
                nxt_x[i] = x[i+1];
            end
            nxt_x[13] = (PE_valid)? x_result: x[14];
    end
    else if (state == state_XDONE)begin
            nxt_x[0] = x[14];
            nxt_x[1] = x[15];
            for (i = 2; i < 16 ; i = i +1) begin
                nxt_x[i] = x[i-2];
            end
    end
    else begin
        for (i = 0;i < 16 ; i = i +1) begin
            nxt_x[i] = x[i];
        end
    end
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
// always @(*) begin
//     case (state)
//         state_UPDATE: begin // update x_addr
//             nxt_x_addr = x_addr + 1;
//         end 
//         state_XDONE: begin // reset x_addr when one iteration is done
//             nxt_x_addr = 0;
//         end
//         state_OUTPUT: begin // output x_addr for output
//             nxt_x_addr = x_addr + 1;
//             // for(i=0; i<16; i=i+1) $display("x[",i+1,"] = %h",x[i]);
//         end
//         default: nxt_x_addr = x_addr;
//     endcase
// end
// always @(posedge clk) begin
//     if (reset) begin
//         x_addr <= 0;
//     end
//     else begin
//         x_addr <= nxt_x_addr;
//     end
// end
always @(*) begin
    case (state) 
        state_PE: nxt_counter = counter + 1;
        state_OUTPUT: nxt_counter = counter + 1;
        default: nxt_counter = 0;
    endcase
end
always @(posedge clk) begin
    if (reset) begin
        counter <= 0;
    end
    else begin
        counter <= nxt_counter;
    end
end
//--------------------------------------
// Processing x values
//--------------------------------------
wire signed [31:0] x1, x2, x3, x4, x5, x6;
//--------------------------------------
assign x1 = (counter < 5'd3 ) ? 32'b0: x[13];
assign x2 = (counter > 5'd14) ? 32'b0: x[ 1];
assign x3 = (counter < 5'd3)  ? 32'b0: x[13];
assign x4 = (counter > 5'd13) ? 32'b0: x[ 2];
assign x5 = (counter <  5'd3) ? 32'b0: x[13];
assign x6 = (counter > 5'd12) ? 32'b0: x[ 3];
assign PE_en = (state == state_PE)? 1'b1: 1'b0;
// initial begin
//     $monitor("%d : x1 = %.10f, x2 = %.10f, x3 = %.10f, x4 = %.10f, x5 = %.10f, x6 = %.10f, b = %.10f\n",$time, x1/65536, x2/65536, x3/65536, x4/65536, x5/65536, x6/65536, b[0]/65536);
// end
PE PE0( .clk(clk),
        .en(PE_en),
        .reset(reset),
        .x1(x1), .x2(x2), .x3(x3), .x4(x4), .x5(x5), .x6(x6),
        .b_in(b[0]),
        .x_out(x_result),
        .valid(PE_valid),
        .counter(counter)
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
assign x_out = x[counter];
assign out_valid = (state == state_OUTPUT)? 1'b1: 1'b0;
endmodule

//--------------------------------------
// Processing Element
//--------------------------------------
module PE ( clk, reset, en, x1, x2, x3, x4, x5, x6, b_in, x_out, valid, counter);
    input clk, reset, en;
    input signed [31:0] x1, x2, x3, x4, x5, x6;
    input signed [31:0] b_in;
    input [4:0] counter;
    output signed [31:0] x_out;
    output valid;
    //--------------------------------------
    // reg/net declaration
    //--------------------------------------
    // reg [4:0] counter, nxt_counter;
    wire signed [35:0] mul13_1;
    wire signed [34:0] mul6_1;
    // wire signed [32:0] add_1;
    wire signed [36:0] add_2;
    wire signed [33:0] add_3;
    wire signed [34:0] mul6_2;
    wire signed [35:0] mul13_2;
    wire signed [39:0] add_6;
    wire signed [31:0] nxt_divide_20;

    reg signed [37:0] add_4, nxt_add_4;
    reg signed [38:0] add_5, nxt_add_5;
    reg signed [31:0] divide_20;
    //--------------------------------------
    assign x_out = nxt_divide_20;
    assign valid = (counter >= 2)? 1'b1: 1'b0;

    assign mul13_1   = {x2[31], x2, 3'b0} + {{2{x2[31]}}, x2, 2'b0}+ {{4{x2[31]}}, x2};
    assign mul6_1    = {x4[31], x4, 2'b0} + {{2{x4[31]}}, x4, 1'b0};
    assign add_2     = mul13_1 - mul6_1;
    assign add_3     = x6 + b_in + x5;
    assign mul6_2    = {x3[31], x3, 2'b0} + {{2{x3[31]}}, x3, 1'b0};
    assign mul13_2   = {x1[31], x1, 3'b0} + {{2{x1[31]}}, x1, 2'b0}+ {{4{x1[31]}}, x1};
    assign add_6     = add_5 + mul13_2;

    divide_by20 div17(.in_div(add_6), .res(nxt_divide_20));
    // initial begin
    //     $display("0426");
    //     $monitor("%d : x1 = %d; test = %h", $time, x1,  add_6);
    // end
    //--------------------------------------
    // counter
    //--------------------------------------
    always @(*) begin
        nxt_add_4 = add_2 + add_3;
        nxt_add_5 = add_4 - mul6_2;
    end
    always @(posedge clk) begin
            add_4 <= nxt_add_4;
            add_5 <= nxt_add_5;
            divide_20 <= nxt_divide_20;
    end
endmodule

// module divide_by20(in_div, res);
//     input signed [36:0] in_div;
//     output signed [31:0] res;
//     parameter ACCU = 43;
//     wire [ACCU : 0] tmp;
//     wire [ACCU - 37:0] res_tmp1;
//     wire [4:0] res_tmp2;
//     assign tmp = in_div << (ACCU - 36); 
//     assign {res_tmp2, res, res_tmp1} =  {{ 5{tmp[ACCU]}}, tmp[ACCU: 5]}+  {{ 6{tmp[ACCU]}}, tmp[ACCU: 6]}+  {{ 9{tmp[ACCU]}}, tmp[ACCU: 9]}+ 
//                                         {{10{tmp[ACCU]}}, tmp[ACCU:10]}+  {{13{tmp[ACCU]}}, tmp[ACCU:13]}+  {{14{tmp[ACCU]}}, tmp[ACCU:14]}+
//                                         {{17{tmp[ACCU]}}, tmp[ACCU:17]}+  {{18{tmp[ACCU]}}, tmp[ACCU:18]}+  {{21{tmp[ACCU]}}, tmp[ACCU:21]}+
//                                         {{22{tmp[ACCU]}}, tmp[ACCU:22]}+  {{25{tmp[ACCU]}}, tmp[ACCU:25]}+  {{26{tmp[ACCU]}}, tmp[ACCU:26]}+
//                                         {{29{tmp[ACCU]}}, tmp[ACCU:29]}+  {{30{tmp[ACCU]}}, tmp[ACCU:30]}+  {{33{tmp[ACCU]}}, tmp[ACCU:33]}+
//                                         {{34{tmp[ACCU]}}, tmp[ACCU:34]};
// endmodule
//0.0000110011001100110011001100110011
module divide_by20 (in_div, res);
    input signed [39:0] in_div;
    output signed [31:0] res;
    wire signed [32:0] zero_05;
    wire signed [72:0] tmp;
    assign zero_05 = 33'b000011001100110011001100110011001; //This is 0.05 in fixed point
    assign tmp = in_div * zero_05;
    assign res = tmp[64:33];
endmodule