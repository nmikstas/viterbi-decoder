`timescale 1ns / 1ps

module viterbi_top(
    input  fpga_clk,            //100MHz system clock.
    input  [15:0]sw,            //Test parameter buttons.
    input  btn,                 //Start button.
    
    output error_injected,      //Indicates where error is injected into encoded bits.
    output test_active,         //Indicates test in progress.
    output [1:0]enc_out,        //Convolutional encoder output.
    output decoder_out,         //Decoder output.
    output error_indicator_out, //output from error detection XOR gate.
    output delay_line_out       //Random input data after delay line.
    );
    
    wire clk; //25MHz clock.
    wire input_stream;
    wire error_indicator_in;
    wire delay_line_in;
    wire decoder_in;
    wire [1:0]enc_pre_err;
    wire [1:0]enc_post_err;
    
    //Error injection state machine. 
    viterbi_state_machine vsm(.clk(clk), .rst(1'b0), .btn(btn), .sw(sw), .enc_pre_err(enc_pre_err[1:0]),
                              .decoder_in(decoder_in), .error_indicator_in(error_indicator_in),
                              .delay_line_in(delay_line_in), .enc_post_err(enc_post_err[1:0]), 
                              .enc_out(enc_out[1:0]), .error_injected(error_injected), .decoder_out(decoder_out),
                              .error_indicator_out(error_indicator_out), .delay_line_out(delay_line_out),
                              .test_active(test_active));    
    
    //Output error indicator.
    assign error_indicator_in = delay_line_in ^ decoder_in;
    
    //Divide 100MHz system clock down to 25MHz.
    clk_div c_div(.clk_in1(fpga_clk), .clk_out1(clk));
    
    //Logical shift register for random input generation.
    lfsr num_gen(.clk(clk), .rst(1'b0), .output_stream(input_stream));
    
    //Convolutional encoder.
    encoder enc(.clk(clk), .rst(1'b0), .din(input_stream), .enc(enc_pre_err[1:0]));
    
    //Delay line.
    delay_line del(.clk(clk), .rst(1'b0), .din(input_stream), .dout(delay_line_in));
   
    //Viterbi decoder.
    doDecode dec(.ap_clk(clk), .ap_rst(1'b0), .ap_start(1'b1), .ap_done(), 
                 .ap_idle(), .ap_ready(), .indat_V(enc_post_err[1:0]), 
                 .outdat_V(decoder_in), .outdat_V_ap_vld());    
endmodule
