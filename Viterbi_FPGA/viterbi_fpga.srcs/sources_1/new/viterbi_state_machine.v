`timescale 1ns / 1ps

module viterbi_state_machine(
    //System inputs.
    input clk,
    input rst,
    input btn,
    input [15:0]sw,
    
    //Viterbi inputs.
    input [1:0]enc_pre_err,
    input decoder_in,
    input error_indicator_in,
    input delay_line_in,
    
    //Viterbi outputs.
    output [1:0]enc_post_err, //To decoder.
    output [1:0]enc_out,
    output error_injected,
    output decoder_out,
    output error_indicator_out,
    output delay_line_out,
    output test_active
    );
    
    localparam PRE_BITS     = 8'h7F;
    localparam POST_BITS    = 8'hA3;
    
    localparam IDLE         = 3'b000;
    localparam PRE_ERROR    = 3'b001;
    localparam ERROR_INJECT = 3'b010;
    localparam POST_ERROR   = 3'b011;
    localparam WAIT         = 3'b100;
    
    reg [7:0]total_errors     = 8'h00;
    reg [7:0]this_err_count   = 8'h00;   
    reg [7:0]this_bit_count   = 8'h00;
    
    wire error_injected0;
    wire error_injected1;
    
    //Assign decoder input bits.
    assign {error_injected0, enc_post_err[0]} = 
           ((state == ERROR_INJECT) && sw[12] && (sw[15:14] == 2'b01)) ? 2'b10 :                    //Force to 0.
           ((state == ERROR_INJECT) && sw[12] && (sw[15:14] == 2'b10)) ? 2'b11 :                    //Force to 1.
           ((state == ERROR_INJECT) && sw[12] && (sw[15:14] == 2'b11)) ? {1'b1, ~enc_pre_err[0]} :  //Invert bit.
           {1'b0, enc_pre_err[0]};                                                                  //No error.
    
    //Assign decoder input bits.                                                      
    assign {error_injected1, enc_post_err[1]} =
           ((state == ERROR_INJECT) && sw[13] && (sw[15:14] == 2'b01)) ? 2'b10 :                    //Force to 0.
           ((state == ERROR_INJECT) && sw[13] && (sw[15:14] == 2'b10)) ? 2'b11 :                    //Force to 1.
           ((state == ERROR_INJECT) && sw[13] && (sw[15:14] == 2'b11)) ? {1'b1, ~enc_pre_err[1]} :  //Invert bit.
            {1'b0, enc_pre_err[1]};                                                                 //No error.
    
    //Assign error injected bit.
    assign error_injected = error_injected0 | error_injected1;
    
    //Assign test active bit.
    assign test_active = (state == PRE_ERROR || state == ERROR_INJECT || state == POST_ERROR) ? 1'b1 : 1'b0;
    
    //Assign encoder out bits.
    assign enc_out[1:0] = (state == PRE_ERROR || state == ERROR_INJECT || state == POST_ERROR) ? enc_post_err[1:0] : 2'b00;
    
    //Assign decoder out bit.
    assign decoder_out = (state == PRE_ERROR || state == ERROR_INJECT || state == POST_ERROR) ? decoder_in : 1'b0;
    
    //Assign error indicator out bit.
    assign error_indicator_out = (state == PRE_ERROR || state == ERROR_INJECT || state == POST_ERROR) ? error_indicator_in : 1'b0;
    
    //Assign delay line out bit.
    assign delay_line_out = (state == PRE_ERROR || state == ERROR_INJECT || state == POST_ERROR) ? delay_line_in : 1'b0;
    
    //State registers.
    reg [2:0]state       = IDLE;
    reg [2:0]next_state  = IDLE;
    
    always @(posedge clk) begin
        if(rst) begin
            state           <= IDLE;
            total_errors    <= 8'h00;
            this_err_count  <= 8'h00;
            this_bit_count  <= 8'h00;
        end
        
        //This state logic.
        else begin
            state        <= next_state;
            total_errors <= sw[7:0];
            
            if(state == IDLE) begin
                this_err_count  <= 8'h00;
                this_bit_count  <= 8'h00;
            end
            
            if(state == PRE_ERROR) begin
                this_err_count  <= 8'h00;
                this_bit_count  <= this_bit_count + 1'b1;
            end
            
            if(state == ERROR_INJECT) begin
                this_err_count  <= this_err_count + 1'b1;
                this_bit_count  <= 8'h00;
            end
            
            if(state == POST_ERROR) begin
                this_err_count  <= 8'h00;
                this_bit_count  <= this_bit_count + 1'b1;
            end
            
            if(state == WAIT) begin
                this_err_count  <= 8'h00;
                this_bit_count  <= 8'h00;
            end
        end    
    end
    
    //Next state logic.
    always @(*) begin
        case(state)
            IDLE         : next_state = btn                                    ? PRE_ERROR    : IDLE;
            PRE_ERROR    : next_state = (this_bit_count < PRE_BITS)            ? PRE_ERROR    : 
                                        (total_errors > 8'h00)                 ? ERROR_INJECT : POST_ERROR;
            ERROR_INJECT : next_state = (this_err_count + 1'b1 < total_errors) ? ERROR_INJECT : POST_ERROR;
            POST_ERROR   : next_state = (this_bit_count < POST_BITS)           ? POST_ERROR   : WAIT;
            WAIT         : next_state = btn                                    ? WAIT         : IDLE;
            default      : next_state = IDLE;     
        endcase
    end
    
endmodule
