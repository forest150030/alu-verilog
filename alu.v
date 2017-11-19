module DFF(clk,in,out);
  parameter n=1;//width
  input clk;
  input [n-1:0] in;
  output [n-1:0] out;
  reg [n-1:0] out;
  
  always @(posedge clk)
    out = in;
endmodule // DFF

module Decoder(in, out);
   parameter m = 1;
   parameter n = 2;
   input [m-1:0] in;
   output [n-1:0] out;
   
   assign out = 1<<in;
endmodule // Decoder

module Mux2(a1, a0, sel, out);
   parameter k = 1;
   input [k-1:0] a0, a1;
   input [1:0] sel;
   output [k-1:0] out;
   assign out = ({k{sel[1]}} & a1) |
		({k{sel[0]}} & a0);
endmodule // Mux2
 
module Mux3(a2, a1, a0, s, b);
   parameter k = 1;
   input [k-1:0] a2, a1, a0;  // inputs
   input [2:0] s; // one-hot select
   output [k-1:0] b ;
   
   assign b = ({k{s[2]}} & a2) | 
              ({k{s[1]}} & a1) |
              ({k{s[0]}} & a0);
endmodule // Mux3

module Mux10(a9, a8, a7, a6, a5, a4, a3, a2, a1, a0, s, b);
   parameter k = 1;
   input [k-1:0] a9, a8, a7, a6, a5, a4, a3, a2, a1, a0 ;  // inputs
   input [9:0] s ; // one-hot select
   output [k-1:0] b ;
   
   assign b = ({k{s[9]}} & a9) |
              ({k{s[8]}} & a8) |
              ({k{s[7]}} & a7) |
              ({k{s[6]}} & a6) |
              ({k{s[5]}} & a5) |
              ({k{s[4]}} & a4) |
              ({k{s[3]}} & a3) |
              ({k{s[2]}} & a2) |
              ({k{s[1]}} & a1) |
              ({k{s[0]}} & a0);
endmodule // Mux10

module OpCL(rst, op, pwr, opsel);
   input rst, pwr;
   input [3:0] op;
   output [9:0] opsel;
   wire [1:0] dec12Out;
   wire [15:0] dec416Out;
  
   Decoder #(1,2) dec12(rst, dec12Out);
   Decoder #(4,16) dec416(op, dec416Out);
   Mux2 #(10) m(10'b1000000000, {1'b0, {dec416Out[8:1] & {8{pwr}}, !pwr}}, dec12Out, opsel);
endmodule // OpCL

module PwrCL(rst, on, off, pwrsel);
   input rst, on, off;
   output [2:0] pwrsel;

   assign pwrsel = {(~rst & ~on & ~off),  //ALL OFF - Remain in current state. 
		    (rst | on),           //RESET/TURN ON - ALU is in ON state.
		    (~rst & ~on & ~off)}; //TURN OFF - ALU is in OFF state.
endmodule // powerCL

module ALU(clk, rst, in, op, on, off, out) ;
   parameter n=8;
   input clk, rst, on, off;
   input [3:0] op;
   input [n-1:0] in;
   output [n-1:0] out;
   wire powerMuxOut, powerOut;
   wire [2:0] pwrsel;
   wire [9:0] opsel;
   wire [n-1:0] outadd, outsub, outmult, outandd, outorr, outnott, outxorr, ffout;
   
   DFF #(n) result(clk, out, ffout);
   DFF power(clk, powerMuxOut, powerOut);
   PwrCL pwrSelect(rst, on, off, pwrsel);
   Mux3 powerMux(powerOut, 1'b1, 1'b0, pwrsel, powerMuxOut);
   OpCL opSelect(rst, op, powerMuxOut, opsel);
   Mux10 #(n) operation({n{1'b0}}, outmult, outadd, outsub, outandd, outorr, outxorr, outnott, in, ffout, opsel, out);   
   adder #(n) addy(ffout, in, outadd);
   subber #(n) subby(ffout, in, outsub);
   multer #(n) multy(ffout,in, outmult);
   ander #(n) andy(ffout, in, outandd);
   orrer #(n) orry(ffout, in, outorr);
   notter #(n) notty(ffout, outnott);
   xorrer #(n) xorry(ffout, in, outxorr);
endmodule // ALU

module adder(Num1, Num2, out) ;
   parameter k = 1;
   input [k-1:0] Num1, Num2;
   output [k-1:0] out;
   assign out = Num1+Num2;
endmodule

module subber(Num1, Num2, out) ;
   parameter k = 1;
   input [k-1:0] Num1, Num2;
   output [k-1:0] out;
   assign out = Num1-Num2;
endmodule

module multer(Num1, Num2, out);
   parameter k = 1;
   input [k-1:0] Num1, Num2;
   output [k-1:0] out;
   assign out = Num1*Num2;
endmodule

module ander(Num1, Num2, out);
   parameter k = 1;
   input [k-1:0] Num1, Num2;
   output [k-1:0] out;
   assign out = (Num1 & Num2);
endmodule

module orrer(Num1,Num2,out);
   parameter k = 1;
   input [k-1:0] Num1, Num2;
   output [k-1:0] out;
   assign out = Num1|Num2;
endmodule

module notter(Num1, out);
   parameter k = 1;
   input [k-1:0] Num1;
   output [k-1:0] out;
   assign out = ~Num1;
endmodule

module xorrer(Num1,Num2,out);
   parameter k = 1;
   input [k-1:0] Num1, Num2;
   output [k-1:0] out;
   assign out = Num1 ^ Num2;
endmodule // xorrer

`define NOP  4'b0000;
`define LOAD 4'b0001; 
`define NOT  4'b0010; 
`define XOR  4'b0011; 
`define OR   4'b0100; 
`define AND  4'b0101; 
`define SUB  4'b0110; 
`define ADD  4'b0111; 
`define	MULT 4'b1000;

module TestBench;
   parameter n=8;
   reg clk, 
       rst, 
       on, 
       off;
   reg [3:0] op;
   reg [n-1:0] in;   
   wire [n-1:0] out;

   ALU ayy(clk, rst, in, op, on, off, out);
   
   initial begin
      clk = 1 ; #5 clk = 0 ;
      $display("|Clock|Reset|IN      |OUT     |OP       |ON|OFF|IN |OUT|PWR|");
      $display("|-----+-----+--------+--------+---------+--+---+---+---+---+");
      forever
	begin
	   $display("|    %b|    %b|%b|%b|%b %s| %b|  %b|%d|%d|  %b|", clk, rst, in, out, op, 
		    ((op == 4'b0000) ? "NOP" : 
		     ((op == 4'b0001) ? "LOAD" : 
		      ((op == 4'b0010) ? "NOT" : 
		       ((op == 4'b0011) ? "XOR" : 
			((op == 4'b0100) ? "OR" : 
			 ((op == 4'b0101) ? "AND" : 
			  ((op == 4'b0110) ? "SUB" : 
			   ((op == 4'b0111) ? "ADD" : 
			    ((op == 4'b1000) ? "MULT" : "????"))))))))), on, off, in, out, ayy.powerMuxOut);
           #5 clk = 1 ; 
	   $display("|    %b|    %b|%b|%b|%b %s| %b|  %b|%d|%d|  %b|", clk, rst, in, out, op, 
		    ((op == 4'b0000) ? "NOP" : 
		     ((op == 4'b0001) ? "LOAD" : 
		      ((op == 4'b0010) ? "NOT" : 
		       ((op == 4'b0011) ? "XOR" : 
			((op == 4'b0100) ? "OR" : 
			 ((op == 4'b0101) ? "AND" : 
			  ((op == 4'b0110) ? "SUB" : 
			   ((op == 4'b0111) ? "ADD" : 
			    ((op == 4'b1000) ? "MULT" : "????"))))))))), on, off, in, out, ayy.powerMuxOut);
	   #5 clk = 0 ;
	end
   end
   // input stimuli
   initial begin
      rst = 0; op = `NOP; in = 8'b00000000; on = 0; off = 0;
      #10
      #10 rst = 0 ; op = `NOP  ; in = 8'b00000000; on = 0; off = 0;
      #10 rst = 1 ; op = `NOP  ; in = 8'b00000000; on = 0; off = 0;
      #10 rst = 0 ; op = `ADD  ; in = 8'b00010000; on = 0; off = 1;
      #10 rst = 0 ; op = `NOP  ; in = 8'b00000110; on = 0; off = 0;
      #10 rst = 0 ; op = `ADD  ; in = 8'b00000010; on = 1; off = 0;
      #10 rst = 0 ; op = `ADD  ; in = 8'b00000010; on = 0; off = 0;
      #10 rst = 0 ; op = `SUB  ; in = 8'b00000100; on = 0; off = 0;
      #10 rst = 0 ; op = `NOP  ; in = 8'b00000000; on = 0; off = 0;
      #10 rst = 0 ; op = `ADD  ; in = 8'b00000110; on = 0; off = 0;
      #10 rst = 0 ; op = `NOP  ; in = 8'b00000000; on = 0; off = 0;
      #10 rst = 0 ; op = `NOP  ; in = 8'b00000000; on = 0; off = 0;
      #10 rst = 0 ; op = `NOP  ; in = 8'b00000000; on = 0; off = 0;
      #10 rst = 0 ; op = `SUB  ; in = 8'b00000001; on = 0; off = 0;
      #10 rst = 0 ; op = `NOP  ; in = 8'b00000000; on = 0; off = 0;
      #10 rst = 0 ; op = `MULT ; in = 8'b00000100; on = 0; off = 0;
      #10 rst = 0 ; op = `NOP  ; in = 8'b00000000; on = 0; off = 0;
      #10 rst = 0 ; op = `AND  ; in = 8'b00000110; on = 0; off = 0;
      #10 rst = 0 ; op = `NOP  ; in = 8'b00000000; on = 0; off = 0;
      #10 rst = 0 ; op = `OR   ; in = 8'b00001010; on = 0; off = 0;
      #10 rst = 0 ; op = `NOP  ; in = 8'b00000000; on = 0; off = 0;
      #10 rst = 0 ; op = `NOT  ; in = 8'b00000000; on = 0; off = 0;
      #10 rst = 0 ; op = `NOP  ; in = 8'b00000000; on = 0; off = 0;
      #10 rst = 0 ; op = `XOR  ; in = 8'b01001001; on = 0; off = 0;
      #10 rst = 0 ; op = `LOAD ; in = 8'b11111111; on = 0; off = 0;
      #10 rst = 0 ; op = `NOP  ; in = 8'b00000000; on = 0; off = 1;
      #10 rst = 0 ; op = `NOP  ; in = 8'b00000000; on = 0; off = 0;
      #10 rst = 0 ; op = `ADD  ; in = 8'b00101001; on = 0; off = 0;
      #10 rst = 0 ; op = `NOP  ; in = 8'b00000000; on = 0; off = 0;
      #10 $finish ;
      $stop;
   end
endmodule
