`timescale 1ns/100ps

module square_16b_pipe_new_tb;

   reg a0, a1, a2, a3, b0, b1, b2, b3, c0, c1, c2, c3, d0, d1, d2, d3, Clock;
   wire [31:0] square;
   
   integer     data_file;
   integer     scan_file;
   real        in_real1, in_real2, in_real3, in_real4;
   integer     in_int1,   in_int2,   in_int3, in_int4;
   reg [15:0]  in_bin1,  in_bin2,  in_bin3, in_bin4;
   wire [15:0] X;
   wire [31:0] wideX = X;
   reg [31:0] X2_1=0, X2_2=0, X2_3=0, X2_4=0;

   square_12b_pipe_new m1 (a0, a1, a2, a3, b0, b1, b2, b3, c0, c1, c2, c3, d0, d1, d2, d3, Clock, square);

   assign X = {a3,a2,a1,a0,b3,b2,b1,b0,c3,c2,c1,c0,d0,d1,d2,d3};

   initial
      begin

         Clock = 1'b0;

         {a3, a2, a1, a0} = 4'b0000;
         {b3, b2, b1, b0} = 4'b0000;
         {c3, c2, c1, c0} = 4'b0000;
         {d3, d2, d1, d0} = 4'b0000;

         repeat(4095)
         begin
         #10   {a3,a2,a1,a0,b3,b2,b1,b0,c3,c2,c1,c0,d3,d2,d1,d0} = {a3,a2,a1,a0,b3,b2,b1,b0,c3,c2,c1,c0,d3,d2,d1,d0} + 16'b0000000000000001;

         X2_4 <= X2_3; X2_3 <= X2_2; X2_2 <= X2_1; X2_1 <= wideX*wideX; 
         //if (X2_4 != square) $display("%0d, %0d, %0d\n", X, X2_4, square);
         $display("%0d, %0d, %0d\n", X, X2_4, square);

         end

         #10  $finish;
      end

   always 
      #5  Clock = ~Clock;

endmodule