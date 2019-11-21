`timescale 1ns / 1ps

module encoder(
    input  clk,
    input  rst,
    input  din,
    output [1:0]enc
    );
    
    reg [2:0]delay_line = 3'b000;
    
    //XOR delay line to create 2-bit encoded output.
    assign enc[0] = delay_line[0] ^ delay_line[1] ^ delay_line[2];
    assign enc[1] = delay_line[0] ^ delay_line[2];
    
    always @(posedge clk) begin
        if(rst) delay_line <= 3'b000;
        else begin
            //Shift contents of delay line.
            delay_line[0] <= din;
            delay_line[1] <= delay_line[0];
            delay_line[2] <= delay_line[1];
        end
    end 
endmodule
