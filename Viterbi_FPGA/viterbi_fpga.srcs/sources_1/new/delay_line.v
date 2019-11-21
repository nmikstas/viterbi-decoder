`timescale 1ns / 1ps

module delay_line#(LENGTH = 36)(
    input  clk,
    input  rst,
    input  din,
    output dout
    );
    
    reg [LENGTH-1:0]delay = 0;
    
    assign dout = delay[LENGTH-2];
    
    always @(posedge clk) begin
        if(rst) delay <= 0;
        else delay <= {delay[LENGTH-2:0], din};
    end
    
endmodule
