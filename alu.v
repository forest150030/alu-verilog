module DFF(clk,in,out);
  parameter n=1;//width
  input clk;
  input [n-1:0] in;
  output [n-1:0] out;
  reg [n-1:0] out;
  
  always @(posedge clk)
  out = in;
 endmodule
 
module Mux3(a2, a1, a0, s, b) ;
  parameter k = 1 ;
  input [k-1:0] a2, a1, a0 ;  // inputs
  input [2:0]   s ; // one-hot select
  output[k-1:0] b ;
   assign b = ({k{s[2]}} & a2) | 
              ({k{s[1]}} & a1) |
              ({k{s[0]}} & a0) ;
endmodule // Mux3

module Mux10(a9, a8, a7, a6, a5, a4, a3, a2, a1, a0, s, b) ;
  parameter k = 1 ;
  input [k-1:0] a9, a8, a7, a6, a5, a4, a3, a2, a1, a0 ;  // inputs
  input [9:0]   s ; // one-hot select
  output[k-1:0] b ;
   assign b = ({k{s[9]}} & a9) |
              ({k{s[8]}} & a8) |
              ({k{s[7]}} & a7) |
              ({k{s[6]}} & a6) |
              ({k{s[5]}} & a5) |
              ({k{s[4]}} & a4) |
              ({k{s[3]}} & a3) |
              ({k{s[2]}} & a2) |
              ({k{s[1]}} & a1) |
              ({k{s[0]}} & a0) ;
endmodule // Mux10


module ALU(clk, rst, in, add, sub, mult, andd, orr, nott, xorr, load, on, off, out) ;
  parameter n=8;
  input clk, rst, add, sub, mult, andd, orr, nott, xorr, load, on, off ;
  input [n-1:0] in;
  output [n-1:0] out;
  wire powerMuxOut, powerOut;
  wire [n-1:0] outadd, outsub, outmult, outandd, outorr, outnott, outxorr, ffout ;
  
  DFF #(n) result(clk, out, ffout) ;
  DFF power(clk, powerMuxOut, powerOut);
  Mux3 powerMux(powerOut, 1'b1, 1'b0, 
  {(~rst & ~on & ~off), //ALL OFF, DOES NOTHING
  (rst | on),			//RESET OR TURN ON
  (~rst & ~on & off)},	//TURN OFF
  powerMuxOut);
  Mux10 #(n) operation({n{1'b0}}, outmult, outadd, outsub, outandd, outorr, outxorr, outnott, in, ffout,
  {(rst),                     																	  		//RESET, RETURN 0
   (~rst & mult & powerMuxOut),   																	    //MULTIPLY
   (~rst & ~mult & add & powerMuxOut),   															    //ADD
   (~rst & ~mult & ~add & sub & powerMuxOut),  													  		//SUBTRACT
   (~rst & ~mult & ~add & ~sub & andd & powerMuxOut),  											  		//AND
   (~rst & ~mult & ~add & ~sub & ~andd & orr & powerMuxOut),   									  	 	//OR
   (~rst & ~mult & ~add & ~sub & ~andd & ~orr & xorr & powerMuxOut),  								    //XOR
   (~rst & ~mult & ~add & ~sub & ~andd & ~orr & ~xorr & nott & powerMuxOut),  						    //NOT
   (~rst & ~mult & ~add & ~sub & ~andd & ~orr & ~xorr & ~nott & load & powerMuxOut), 				    //LOAD
   ((~rst & ~add & ~sub & ~mult & ~andd & ~orr & ~nott & ~xorr & ~load & powerMuxOut) | ~powerMuxOut)}, //ALL OFF, DOES NOTHING
   out) ;
	
	adder #(n) addy(ffout,in,outadd);
	subber #(n) subby(ffout, in, outsub);
	multer #(n) multy(ffout,in, outmult);
	ander #(n) andy(ffout, in, outandd);
	orrer #(n) orry(ffout, in, outorr);
	notter #(n) notty(ffout, outnott);
	xorrer #(n) xorry(ffout, in, outxorr);
  
  
endmodule

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
endmodule


module TestBench ;
  reg clk, rst, add, sub, mult, andd, orr, nott, xorr, load, on, off;
  parameter n=8;
  reg [n-1:0] in;
  wire [n-1:0] out;
  
  ALU ayy(clk, rst, in, add, sub, mult, andd, orr, nott, xorr, load, on, off, out) ;
  
  initial begin
    clk = 1 ; #5 clk = 0 ;
	    $display("|Clock|Reset|IN      |OUT     |M|A|S|A|O|X|N|L|ON|OFF|IN |OUT|PWR|");
	    $display("|-----+-----+--------+--------+-+-+-+-+-+-+-+-+--+---+---+---+---+");
    forever
      begin
        $display("|    %b|    %b|%b|%b|%b|%b|%b|%b|%b|%b|%b|%b| %b|  %b|%d|%d|  %b|",clk,rst, in, out,mult,add,sub,andd,orr,xorr,nott,load,on,off,in,out,ayy.powerMuxOut);
        #5 clk = 1 ; 
        $display("|    %b|    %b|%b|%b|%b|%b|%b|%b|%b|%b|%b|%b| %b|  %b|%d|%d|  %b|",clk,rst, in, out,mult,add,sub,andd,orr,xorr,nott,load,on,off,in,out,ayy.powerMuxOut);
		#5 clk = 0 ;
      end
    end

  // input stimuli
  initial begin
    rst = 0 ; add=0; sub=0; mult=0; andd=0; orr=0; nott=0; xorr=0; in=8'b00000000; load=0; on=0; off=0;
	#10
    #10 rst = 0 ; add=0; sub=0; mult=0; andd=0; orr=0; nott=0; xorr=0; in=8'b00000000; load=0; on=0; off=0;
    #10 rst = 1 ; add=0; sub=0; mult=0; andd=0; orr=0; nott=0; xorr=0; in=8'b00000000; load=0; on=0; off=0;
    #10 rst = 0 ; add=1; sub=0; mult=0; andd=0; orr=0; nott=0; xorr=0; in=8'b00010000; load=0; on=0; off=1;
    #10 rst = 0 ; add=0; sub=0; mult=0; andd=0; orr=0; nott=0; xorr=0; in=8'b00000110; load=0; on=0; off=0;
    #10 rst = 0 ; add=1; sub=0; mult=0; andd=0; orr=0; nott=0; xorr=0; in=8'b00000010; load=0; on=1; off=0;
    #10 rst = 0 ; add=1; sub=0; mult=0; andd=1; orr=0; nott=0; xorr=0; in=8'b00000010; load=0; on=0; off=0;
    #10 rst = 0 ; add=0; sub=1; mult=0; andd=0; orr=0; nott=0; xorr=0; in=8'b00000100; load=0; on=0; off=0;
    #10 rst = 0 ; add=0; sub=0; mult=0; andd=0; orr=0; nott=0; xorr=0; in=8'b00000000; load=0; on=0; off=0;
    #10 rst = 0 ; add=1; sub=0; mult=0; andd=0; orr=0; nott=0; xorr=0; in=8'b00000110; load=0; on=0; off=0;
    #10 rst = 0 ; add=0; sub=0; mult=0; andd=0; orr=0; nott=0; xorr=0; in=8'b00000000; load=0; on=0; off=0;
    #10 rst = 0 ; add=0; sub=0; mult=0; andd=0; orr=0; nott=0; xorr=0; in=8'b00000000; load=0; on=0; off=0;
    #10 rst = 0 ; add=0; sub=0; mult=0; andd=0; orr=0; nott=0; xorr=0; in=8'b00000000; load=0; on=0; off=0;
    #10 rst = 0 ; add=0; sub=1; mult=0; andd=0; orr=0; nott=0; xorr=0; in=8'b00000001; load=0; on=0; off=0;
    #10 rst = 0 ; add=0; sub=0; mult=0; andd=0; orr=0; nott=0; xorr=0; in=8'b00000000; load=0; on=0; off=0;
    #10 rst = 0 ; add=0; sub=0; mult=1; andd=0; orr=0; nott=0; xorr=0; in=8'b00000100; load=0; on=0; off=0;
    #10 rst = 0 ; add=0; sub=0; mult=0; andd=0; orr=0; nott=0; xorr=0; in=8'b00000000; load=0; on=0; off=0;
    #10 rst = 0 ; add=0; sub=0; mult=0; andd=1; orr=0; nott=0; xorr=0; in=8'b00000110; load=0; on=0; off=0;
    #10 rst = 0 ; add=0; sub=0; mult=0; andd=0; orr=0; nott=0; xorr=0; in=8'b00000000; load=0; on=0; off=0;
    #10 rst = 0 ; add=0; sub=0; mult=0; andd=0; orr=1; nott=0; xorr=0; in=8'b00001010; load=0; on=0; off=0;
    #10 rst = 0 ; add=0; sub=0; mult=0; andd=0; orr=0; nott=0; xorr=0; in=8'b00000000; load=0; on=0; off=0;
    #10 rst = 0 ; add=0; sub=0; mult=0; andd=0; orr=0; nott=1; xorr=0; in=8'b00000000; load=0; on=0; off=0;
    #10 rst = 0 ; add=0; sub=0; mult=0; andd=0; orr=0; nott=0; xorr=0; in=8'b00000000; load=0; on=0; off=0;
    #10 rst = 0 ; add=0; sub=0; mult=0; andd=0; orr=0; nott=0; xorr=1; in=8'b01001001; load=0; on=0; off=0;
    #10 rst = 0 ; add=0; sub=0; mult=0; andd=0; orr=0; nott=0; xorr=0; in=8'b00000000; load=0; on=0; off=0;
    #10 rst = 0 ; add=0; sub=0; mult=0; andd=0; orr=0; nott=0; xorr=0; in=8'b00000000; load=0; on=0; off=1;
    #10 rst = 0 ; add=0; sub=0; mult=0; andd=0; orr=0; nott=0; xorr=0; in=8'b00000000; load=0; on=0; off=0;
    #10 rst = 0 ; add=1; sub=0; mult=0; andd=0; orr=0; nott=0; xorr=0; in=8'b00101001; load=0; on=0; off=0;
    #10 rst = 0 ; add=0; sub=0; mult=0; andd=0; orr=0; nott=0; xorr=0; in=8'b00000000; load=0; on=0; off=0;
    #10 $finish ;
	$stop;
  end
endmodule
