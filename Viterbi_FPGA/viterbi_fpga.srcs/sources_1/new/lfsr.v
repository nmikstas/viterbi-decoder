`timescale 1ns / 1ps

module lfsr(
    input clk,
    input rst,
    output output_stream
    );
    
    //Create a linear feedback shift register with
    //polynomial x^19 + x^18 + x^17 + x^14 + 1.
    reg [1:19]lfsr = 19'b 1100110011001100111;
    wire feedback;
    
    assign feedback = ((lfsr[19] ^ lfsr[18]) ^ lfsr[17]) ^ lfsr[14];
    assign output_stream = lfsr[1];
        
    //Update the linear shift feedback register.
    always @(posedge clk) begin
        if(rst) lfsr <= 19'b 1100110011001100111;
        else lfsr <= {feedback, lfsr[1:18]};
    end
endmodule
