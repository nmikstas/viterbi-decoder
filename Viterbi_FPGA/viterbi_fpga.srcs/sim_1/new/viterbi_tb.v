`timescale 1ns / 1ps

module viterbi_tb;
    reg  fpga_clk = 1'b0;    
    reg [15:0]sw = 16'h0;
    reg btn = 1'b0;
    
    //Top level signals.
    wire clk;
    wire error_injected;      
    wire test_active; 
    wire [1:0]enc_out;
    wire decoder_out;
    wire error_indicator_out;
    wire delay_line_out;
    wire [2:0]state;
    
    //Internal signals.
    wire input_stream;
    wire decoder_in;
    
    viterbi_top uut(.fpga_clk(fpga_clk), .sw(sw), .btn(btn), .error_injected(error_injected),
                    .test_active(test_active), .enc_out(enc_out[1:0]), .decoder_out(decoder_out),
                    .error_indicator_out(error_indicator_out), .delay_line_out(delay_line_out));

    always #5 fpga_clk = ~fpga_clk;
    
    assign input_stream = uut.input_stream;
    assign decoder_in = uut.decoder_in;
    assign clk = uut.clk;
    assign state = uut.vsm.state;
    
    initial begin
        #100
        sw[7:0] = 8'b00000011;
        sw[15:14] = 2'b01;
        sw[13:12] = 2'b01;
        
        #1000 btn = 1'b1;
        #1000 btn = 1'b0;
    end    
endmodule
