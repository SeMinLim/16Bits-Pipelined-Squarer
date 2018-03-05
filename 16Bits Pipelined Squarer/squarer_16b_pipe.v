////////////////////////////////////////////////////////////////////////
//
//  My 16-b squarer w/ 20bit ripple carry adder at the final
//
////////////////////////////////////////////////////////////////////////


module HA (s, c, x, y);
   input x, y;
   output s, c;
   xor(s, x, y);
   and(c, x, y);
endmodule

module FA (s, co, x, y, ci);
   input x, y, ci;
   output s, co;
   wire p, g, pandci;
   HA  HA1 (p, g, x, y),
       HA2 (s, pandci, p, ci);
   or  O1  (co, pandci, g); 
endmodule

macromodule mult_4b (a0,  a1,  a2,  a3,  b0,  b1,  b2,  b3,     
                     m06, m05, m04, m03, m02, m01, m00,
                          m15, m14, m13, m12, m11,
                               m24, m23, m22,
                                    m33                     );
   input  a0, a1, a2, a3, b0, b1, b2, b3;
   output m06, m05, m04, m03, m02, m01, m00, m15, m14, m13, m12, m11,
          m24, m23, m22, m33;   

   wire m00 = a0 & b0, 
        m01 = a1 & b0, 
        m02 = a2 & b0, 
        m03 = a3 & b0, 
        m04 = a3 & b1, 
        m05 = a3 & b2, 
        m06 = a3 & b3, 
        m11 = a0 & b1, 
        m12 = a1 & b1, 
        m13 = a2 & b1, 
        m14 = a2 & b2, 
        m15 = a2 & b3, 
        m22 = a0 & b2, 
        m23 = a1 & b2, 
        m24 = a1 & b3, 
        m33 = a0 & b3; 
          
endmodule
  
/////////////////////////////////////////////////////////
//
//    Module 2cd + d^2
//
//           a    b    c
//           a    b    c
//   --------------------------
//       2bc 0           
//          2bc   c2
//               2bc   c2
//

module D2_2CD (c0, c1, c2, c3, d0, d1, d2, d3, D2_2CD_C, D2_2CD_S);

   input c0, c1, c2, c3, d0, d1, d2, d3;
   output [11:0] D2_2CD_S;    // Result's Sum vector
   output [12:7] D2_2CD_C;    // Result's Carry vector


// Level 1
   // generation of CD 
   wire   m06, m05, m04, m03, m02, m01, m00, m15, m14, m13, m12, m11,
          m24, m23, m22, m33;   

   mult_4b m1  (c0, c1, c2, c3, d0, d1, d2, d3, 
                m06, m05, m04, m03, m02, m01, m00, 
                     m15, m14, m13, m12, m11, 
                          m24, m23, m22, 
                                m33                  );
                               
   // gen of D^2
   wire      d1N0  =d1 & d0,    d1N0_ = d1 & ~(d0),
             d2N0  =d2 & d0,    d2N1  = d2 & d1,        d2N1_ = d2 & ~(d1),
             d3N0  =d3 & d0,    d3N1  = d3 & d1,        d3N2  = d3 & d2,       d3N2_ = d3 & ~(d2);

   wire  s15, c16, s16, c17, s17, c18, s18, c19, s19, c110, s110, c111;
   FA FA15  ( s15, c16, m00, d3N1, d2N1), 
      FA16  ( s16, c17, m01, m11,  d3N2_),
      FA17  ( s17, c18, m02, m12,  m22),
      FA18  ( s18, c19, m03, m13,  m23),
      FA19  ( s19, c110,m04, m14,  m24);
   HA HA110 ( s110,c111,m05, m15 );

// Level 2
   wire  c28, c29, c210, s28, s29;
   FA FA27 ( D2_2CD_S[7], c28, c17, s17, d3N2),
       FA28 (         s28, c29, c18, s18, m33 );
      HA29 (         s29, c210,s19, c19);
      
// Level 3
   wire c310, c311, s310;
   HA HA38  (D2_2CD_S[8], D2_2CD_C[9], c28,  s28);              assign  D2_2CD_C[8] = 1'b0;
   HA HA39  (D2_2CD_S[9], c310, c29, s29 );
   FA FA310 (s310, c311, s110, c110, c210 );
        
// Level 4
   HA HA410 (D2_2CD_S[10], D2_2CD_C[11], c310, s310);           assign  D2_2CD_C[10] = 1'b0;
   FA FA411 (D2_2CD_S[11], D2_2CD_C[12], c311, c111, m06);
   
// 1st Part of Ripple-Carry Adder
   assign D2_2CD_S[0] = c0,         
     D2_2CD_S[1] = 1'b0,
     D2_2CD_S[2] = d1N0_;

   wire  r1_c14, r1_c25, r1_c36;
	
   HA HA13  (D2_2CD_S[3], r1_c14,        d2N0,  d1N0 );
   FA FA24  (D2_2CD_S[4], r1_c25,      r1_c14,  d3N0,    d2N1_ );
   HA HA35  (D2_2CD_S[5], r1_c36,      r1_c25,   s15  );
   FA FA46  (D2_2CD_S[6], D2_2CD_C[7], r1_c36,   c16,    s16  );

endmodule

/////////////////////////////////////////////////////////
//
//    Module K = c^2 + 2bd
//
//           a    b    c
//           a    b    c
//   --------------------------
//     K 2bc  0           
//        K  2bc  c2
//            K  2bc   c2
//
module C2_2BD (b0, b1, b2, b3, c0, c1, c2, c3, d0, d1, d2, d3, prev_S, prev_C, C2_2BD_C, C2_2BD_S);

   input  [11:7] prev_S;
   input  [12:7] prev_C;
   input  b0, b1, b2, b3, c0, c1, c2, c3, d0, d1, d2, d3;
   output [15:7]  C2_2BD_S;    // Result's Sum vector
   output [16:9] C2_2BD_C;    // Result's Carry vector

// Level 1
   // generation of BD 
   wire   m06, m05, m04, m03, m02, m01, m00, m15, m14, m13, m12, m11,
          m24, m23, m22, m33;   

   mult_4b m1  (b0, b1, b2, b3, d0, d1, d2, d3, 
                m06, m05, m04, m03, m02, m01, m00, 
                     m15, m14, m13, m12, m11, 
                          m24, m23, m22, 
                               m33                  );
   // gen of C^2                            
   wire c1N0  =c1 & c0, 
        c2N0  =c2 & c0, c2N1  =c2 & c1,  c2N1_ =c2 & ~(c1),
        c3N0  =c3 & c0, c3N1  =c3 & c1,  c3N2  =c3 & c2;

   // 1st level of CSA tree        
   wire  s110, c111, s111_1, c112_1, s111_2, c112_2, s112_1, c113_1, s112_2, c113_2, s113_1, c114_1, s113_2, c114_2, s114, c115;
   
   FA FA110   (         s110,   c111,        m11,        c1,   c1N0 ),       
      FA111_1 (       s111_1, c112_1, prev_C[11], prev_S[11],   m02 ),
      FA111_2 (       s111_2, c112_2,        m12,        m22,  c2N0 ),
      FA112_1 (       s112_1, c113_1,        m03,        m13,   m23 ),
      FA112_2 ( C2_2BD_C[12], c113_2,        m33,       c3N0, c2N1_ );
   HA HA113   (       s113_1, c114_1,        m04,        m14        );   
   FA   FA113   (       s113_2, c114_2,        m24,       c3N1,  c2N1 ),
      FA114   (         s114,   c115,        m15,         c3,  c3N2 );
      
// Level 2
   wire  c212, s212, c213, s213, c214, s214, c215;

   FA FA29    (  C2_2BD_S[9], C2_2BD_C[10],  prev_C[9],  prev_S[9],    m00 ),
      FA210   ( C2_2BD_S[10], C2_2BD_C[11],       s110, prev_S[10],    m01 ),
      FA211   ( C2_2BD_S[11],         c212,       c111,     s111_1, s111_2 ),
      FA212   (         s212,         c213, prev_C[12],     c112_1, c112_2 ),
      FA213   (         s213,         c214,     s113_2,     c113_1, c113_2 ),
      FA214   (         s214,         c215,     c114_1,     c114_2,    m05 );
      
// Level 3
   
   FA FA312   ( C2_2BD_S[12], C2_2BD_C[13],     s212, c212, s112_1 ),
      FA313   ( C2_2BD_S[13], C2_2BD_C[14],     c213, s213, s113_2 ),
      FA314   ( C2_2BD_S[14], C2_2BD_C[15],     s214, c214,   s114 ),
      FA315   ( C2_2BD_S[15], C2_2BD_C[16],     c215, c115,    m06 );
      
// 2nd Part of Ripple-Carry Adder

   wire  r2_c18, r2_c29, r2_c310, r2_c411;
	
   HA HA17  (C2_2BD_S[7],        r2_c18,      prev_C[7],   prev_S[7]        );
   FA FA28  (C2_2BD_S[8],   C2_2BD_C[9],         r2_c18,   prev_S[8],    c0 );


endmodule

/////////////////////////////////////////////////////////
//
//   Module 2ad + 2bc
//
//
//
//
//
//
//
//
module AD2_2BC (a0, a1, a2, a3, b0, b1, b2, b3, c0, c1, c2, c3, d0, d1, d2, d3, prev_S, prev_C, AD2_2BC_C, AD2_2BC_S);

   input [16:9] prev_S;
   input [15:9] prev_C;
   input a0, a1, a2, a3, b0, b1, b2, b3, c0, c1, c2, c3, d0, d1, d2, d3;
   output [20:9] AD2_2BC_S;
   output [20:13] AD2_2BC_C;
   
// Level 1
   // generation of AD
   wire   m06, m05, m04, m03, m02, m01, m00, m15, m14, m13, m12, m11,
          m24, m23, m22, m33;   

   mult_4b m1  (a0, a1, a2, a3, d0, d1, d2, d3, 
                m06, m05, m04, m03, m02, m01, m00, 
                     m15, m14, m13, m12, m11, 
                          m24, m23, m22, 
                               m33                  );
                               
   // generation of BC
   wire   u06, u05, u04, u03, u02, u01, u00, u15, u14, u13, u12, u11,
          u24, u23, u22, u33;   

   mult_4b m2  (b0, b1, b2, b3, c0, c1, c2, c3, 
                u06, u05, u04, u03, u02, u01, u00, 
                     u15, u14, u13, u12, u11, 
                          u24, u23, u22, 
                               u33                  );
   
   //1st level of CSA tree
   wire         s113, c114, s114_1, c115_1, s114_2, c115_2, s115_1, c116_1, s115_2, c116_2, s115_3, c116_3;
	wire         s116_1, c117_1, s116_2, c117_2, s116_3, c117_3, s117_1, c118_1, s117_2, c118_2, s118, c119;
	
	FA FA113   (   s113,   c114, prev_S[13],        m00, u00 );
		FA114_1 ( s114_1, c115_1, prev_C[14], prev_S[14], m01 );
		FA114_2 ( s114_2, c115_2,        m11,        u01, u11 );
	HA HA115   ( s115_1, c116_1, prev_C[15], prev_S[15]      );
	FA FA115_1 ( s115_2, c116_2,        m02,        m12, m22 );
		FA115_2 ( s115_3, c116_3,        u02,        u12, u22 );
	HA HA116   ( s116_1, c117_1,        m03,        m13      );
	FA FA116_1 ( s116_2, c117_2,        m23,        m33, u03 );
		FA116_2 ( s116_3, c117_3,        u13,        u23, u33 );
		FA117_1 ( s117_1, c118_1,        m04,        m14, m24 );
		FA117_2 ( s117_2, c118_2,        u04,        u14, u24 );
		FA118   (   s118,   c119,        m15,        u05, u15 );
		
// Level 2
	wire         s214, c215, s215_1, c216_1, s215_2, c216_2, s216_1, c217_1; 
	wire         s216_2, c217_2, s217_1, c218_1, s217_2, c218_2, s218, c219, s219, c220;
	
	FA FA214   (   s214,   c215,   c114, s114_1,     s114_2 );
	HA HA215_1 ( s215_1, c216_1, s115_1, s115_2             );
	FA FA215_2 ( s215_2, c216_2, c115_1, c115_2,     s115_3 );
		FA216_1 ( s216_1, c217_1, c116_2, s116_1,     s116_2 );
		FA216_2 ( s216_2, c217_2, c116_3, s116_3, prev_C[16] );
	HA HA217_1 ( s217_1, c218_1, s117_1, c117_1             );
	FA FA217_2 ( s217_2, c218_2, c117_2, s117_2,     c117_3 );
		FA218   (   s218,   c219,   s118,    m05,     c118_2 );
		FA219   (   s219,   c220,    m06,    u06,       c119 );
		
// Level 3
	wire         c316, s316, c317, s317, c318, s318, c319;
	
	HA HA313   ( AD2_2BC_S[13], AD2_2BC_C[14], prev_C[13],   s113             );   assign AD2_2BC_S[14] = s214;    
	FA FA315   ( AD2_2BC_S[15],          c316,     s215_1,   c215,     s215_1 );   assign AD2_2BC_C[15] = s115_2;
		FA316   (          s316,          c317,     c216_1,   s216, prev_C[16] );   assign AD2_2BC_C[16] = 1'b0;
		FA317   (          s317,          c318,     s217_1, c217_1,     s217_2 );
		FA318   (          s318,          c319,     c218_1,   s218,     c218_2 );

// Level 4
	
	FA FA416   ( AD2_2BC_S[16], AD2_2BC_C[17], s316, c316, s216_2 );
		FA417   ( AD2_2BC_S[17], AD2_2BC_C[18], c317, s317, c217_2 );
	HA HA418   ( AD2_2BC_S[18], AD2_2BC_C[19], s318, c318         );
	FA FA419   ( AD2_2BC_S[19], AD2_2BC_C[20], c319, c219,   s219 );               assign AD2_2BC_S[20] = c220;

// 3rd Part of Ripple-Carry Adder
	wire         r3_c110, r3_c211, r3_c312;
	
	HA HA19    (  AD2_2BC_S[9],       r3_c110, prev_C[9],  prev_S[9]             );
	FA FA210   ( AD2_2BC_S[10],       r3_c211,   r3_c110, prev_C[10], prev_S[10] );
		FA211   ( AD2_2BC_S[11],       r3_c312,   r3_c211, prev_C[11], prev_S[11] );
		FA212   ( AD2_2BC_S[12], AD2_2BC_C[13],   r3_c312, prev_C[12], prev_S[12] );
		
endmodule

/////////////////////////////////////////////////////////
//
//    Module b^2 + 2ac
//
//                a    b    c
//                a    b    c
//   --------------------------
//   2ab  K  2bc  0           
//    a2 2ab  K  2bc   c2
//        a2 2ab  K   2bc   c2
//
module B2_2AC (a0, a1, a2, a3, b0, b1, b2, b3, c0, c1, c2, c3, prev_S, prev_C, B2_2AC_C, B2_2AC_S);

   input  [20:13] prev_S;
   input  [20:13] prev_C;
   input  a0, a1, a2, a3, b0, b1, b2, b3, c0, c1, c2, c3;
   output [24:16] B2_2AC_S;    // Result's Sum vector
   output [24:16] B2_2AC_C;    // Result's Carry vector

// Level 1
   // generation of AC 
   wire   m06, m05, m04, m03, m02, m01, m00, m15, m14, m13, m12, m11,
          m24, m23, m22, m33;   
   mult_4b m1  (a0,  a1,  a2,  a3,  c0,  c1,  c2,  c3, 
                m06, m05, m04, m03, m02, m01, m00, 
                     m15, m14, m13, m12, m11, 
                          m24, m23, m22, 
                               m33                  );
   
   // gen of B^2                               
   wire b1N0  =b1 & b0,  b1N0_ =b1 & ~(b0), 
        b2N0  =b2 & b0,  b2N1  =b2 & b1,    b2N1_ =b2 & ~(b1),
        b3N0  =b3 & b0,  b3N1  =b3 & b1,    b3N2  =b3 & b2,      b3N2_ =b3 & ~(b2);

   // 1st level of CSA tree 
   wire         s116, c117, s117, c118, s118_1, c119_1, s118_2, c119_2, s119_1, c120_1, s119_2, c120_2;
	wire         s120_1, c121_1, s120_2, c121_2, s120_3, c121_3, s121_1, c122_1, s121_2, c122_2, s122, c123;
	
	HA HA116   (   s116,   c117, prev_S[16],        b0          );
	FA FA117   (   s117,   c118, prev_C[17], prev_S[17],   m00  );
		FA118_1 ( s118_1, c119_1, prev_C[18], prev_S[18],   m01  );
		FA118_2 ( s118_2, c119_2,        m11,         b1,  b1N0  );
		FA119_1 ( s119_1, c120_1, prev_C[19], prev_S[19],   m02  );
		FA119_2 ( s119_2, c120_2,        m12,        m23,  b2N0  );
	HA HA120_1 ( s120_1, c121_1, prev_C[20], prev_S[20]         );
	FA FA120_2 ( s120_2, c121_2,        m03,        m13,   m23  );
		FA120_3 ( s120_3, c121_3,        m33,         b2, b2N1_  );
	HA HA121_1 ( s121_1, c122_1,        m04,        m14         );
	FA FA121_2 ( s121_2, c122_2,        m24,       b3N1,  b2N1  );
		FA122   (   s122,   c123,        m15,         b3,  b3N2  );

// Level 2
   wire         c219, s219, c220, s220_1, c221_1, s220_2, c221_2, s221_1, c222_1, s221_2, c222_2, s222, c223;
	
	FA FA218   ( B2_2AC_S[18],   c219,   c118, s118_1, s118_2 );
		FA219   (         s219,   c220, c119_2, s119_1, s119_2 );
	HA HA220_1 (       s220_1, c221_1, s120_1, s120_2         );
	FA	FA220_2 (       s220_2, c221_2, s120_3, c120_1, c120_2 );
	HA HA221_1 (       s221_1, c222_1, c121_1, c121_2         );
	FA FA221_2 (       s221_2, c222_2, c121_3, s121_1, s121_2 );
		FA222   (         s222,   c223,    m05, c122_1, c122_2 );

// Level 3
   wire         c321, s321, c322, s322, c323, s323, c324;
	
	HA HA317   ( B2_2AC_S[17], B2_2AC_C[18],   s117,   c117         );
	FA FA319   ( B2_2AC_S[19], B2_2AC_C[20], c119_1,   c219,   s219 );        assign B2_2AC_C[19] = 1'b0;
		FA320   ( B2_2AC_S[20],         c321, s220_1, s220_2,   c220 );
		FA321   (         s321,         c322, c221_1, c221_2, s221_1 );
		FA322   (         s322,         c323,   s222,   s122, c222_1 );
		FA323   (         s323,         c324,   c223,   c123,    m06 );

// Level 4
	
	FA FA421   ( B2_2AC_S[21], B2_2AC_C[22], c321, s321, s221_2 );            assign B2_2AC_C[21] = 1'b0;
		FA422   ( B2_2AC_S[22], B2_2AC_C[23], s322, c322, c222_2 );
	HA HA423   ( B2_2AC_S[23], B2_2AC_C[24], c323, s323         );            assign B2_2AC_S[24] = c324;


// 4th Part of Ripple-Carry Adder
	wire r4_c114, r4_c215, r4_c316;
	
	HA HA113   ( B2_2AC_S[13],      r4_c114, prev_C[13], prev_S[13]             );
	FA FA214   ( B2_2AC_S[14],      r4_c215,    r4_c114, prev_C[14], prev_S[14] );
		FA315   ( B2_2AC_S[15],      r4_c316,    r4_c215, prev_C[15], prev_S[15] );
	HA HA416   ( B2_2AC_S[16], B2_2AC_C[17],    r4_c316,      s116              );

endmodule

/////////////////////////////////////////////////////////
//
//   Module a^2 + 2ab
//
//
//
//
//
//
//
//
module A2_2AB (a0, a1, a2, a3, b0, b1, b2, b3, prev_S, prev_C, A2_2AB_C, A2_2AB_S);
	
	input [24:17] prev_S;
	input [24:17] prev_C;
	input a0, a1, a2, a3, b0, b1, b2, b3;
	output [31:21] A2_2AB_C;
	output [30:21] A2_2AB_S;
	
// Level 1
	// generation of AB
	wire   m06, m05, m04, m03, m02, m01, m00, m15, m14, m13, m12, m11,
          m24, m23, m22, m33;   
   mult_4b m1  (a0,  a1,  a2,  a3,  b0,  b1,  b2,  b3, 
                m06, m05, m04, m03, m02, m01, m00, 
                     m15, m14, m13, m12, m11, 
                          m24, m23, m22, 
                               m33                  );
	// gen of A^2                               
   wire a1N0  =a1 & a0,  a1N0_ =a1 & ~(a0), 
        a2N0  =a2 & a0,  a2N1  =a2 & a1,    a2N1_ =a2 & ~(a1),
        a3N0  =a3 & a0,  a3N1  =a3 & a1,    a3N2  =a3 & a2,      a3N2_ =a3 & ~(a2);
	
	// 1st level of CSA tree
	wire         c122, s122, c123, s123, c124, s124_1, c125_1, s124_2; 
	wire         c125_2, s125, c126, s126, c127, s127, c128, s128, c129;
	
	HA HA121   ( A2_2AB_S[21],   c122, prev_S[21],  m00       );
	FA FA122   (         s122,   c123, prev_S[22],  m01,  m11 );
		FA123   (         s123,   c124,        m02,  m12,  m22 );
		FA124_1 (       s124_1, c125_1, prev_S[24],  m03,  m13 );
		FA124_2 (       s124_2, c125_2,        m23,  m33,   a0 );
		FA125   (         s125,   c126,        m04,  m14,  m24 );
		FA126   (         s126,   c127,        m05,  m15,   a1 );
	HA HA127   (         s127,   c128,        m06, a2N0       );
	FA FA128   (         s128,   c129,         a2, a2N1, a3N0 );
	
// Level 2
	wire         s222, c223, s223, c224, s224, c225, s225, c226; 
	wire         s226, c227, s227, c228, s228, c229, s229, c230;
	
	FA FA222   ( s222, c223,   s122, c122, prev_C[22] );
		FA223   ( s223, c224,   c123, s123, prev_C[23] );
		FA224   ( s224, c225, s124_1, c124,     s124_2 );
		FA225   ( s225, c226, c125_1, s125,     c125_2 );
		FA226   ( s226, c227,   s126, c126,       a1N0 );
	HA HA227   ( s227, c228,   c127, s127             );
		HA228   ( s228, c229,   s128, c128             );
		HA229   ( s229, c230,   c129, a3N1             );
		
// Level 3
	wire         c326, c330;
	
	HA HA322   ( A2_2AB_S[22], A2_2AB_C[23], s222, c222             );
	FA FA323   ( A2_2AB_S[23], A2_2AB_C[24], c223, s223, prev_S[23] );
		FA324   ( A2_2AB_S[24], A2_2AB_C[25], s224, c224, prev_C[24] );
	HA HA325   ( A2_2AB_S[25],         c326, c225, s225             );
		HA329   ( A2_2AB_S[29], A2_2AB_C[30], c229, s229             );
	FA FA330   ( A2_2AB_S[30], A2_2AB_C[31], c230,   a3,       a3N2 );
	
// Level 4
	
	FA FA426   ( A2_2AB_S[26], A2_2AB_C[27], c326, s226, c226 );
	HA HA427   ( A2_2AB_C[27], A2_2AB_C[28], c227, s227       );
		HA428   ( A2_2AB_S[28], A2_2AB_C[29], s228, c228       );
		
//5th Part of Ripple-Carry Adder
	wire r5_c118, r5_c219, r5_c320;
	
	HA HA117   ( A2_2AB_S[17],      r5_c118, prev_C[17], prev_S[17]             );
	FA FA218   ( A2_2AB_S[18],      r5_c219,    r5_c118, prev_C[18], prev_S[18] );
	HA HA319   ( A2_2AB_S[19],      r5_c320,    r5_c219, prev_S[19]             );
	FA FA420   ( A2_2AB_S[20], A2_2AB_C[21],    r5_c320, prev_C[20], prev_S[20] );
	
endmodule


module square_16b_pipe_new (a0, a1, a2, a3, b0, b1, b2, b3, c0, c1, c2, c3, d0, d1, d2, d3, Clock, square);

   input  a0, a1, a2, a3, b0, b1, b2, b3, c0, c1, c2, c3, d0, d1, d2, d3, Clock;
   output reg [31:0] square;
   
// input registers
   reg     ra0, ra1, ra2, ra3, rb0, rb1, rb2, rb3, rc0, rc1, rc2, rc3, rd0, rd1, rd2, rd3;
   
   always @(posedge Clock)
   begin
      ra0 <= a0;      ra1 <= a1;      ra2 <= a2;      ra3 <= a3;
         rb0 <= b0;      rb1 <= b1;      rb2 <= b2;      rb3 <= b3;
      rc0 <= c0;      rc1 <= c1;      rc2 <= c2;      rc3 <= c3;
		   rd0 <= d0;      rd1 <= d1;      rd2 <= d2;      rd3 <= d3;
   end  

////////////////////////////////////////////
// Stage #1
   wire [12:7] D2_2CD_C;    wire [11:0]  D2_2CD_S;

   D2_2CD U_D2_2CD (rc0, rc1, rc2, rc3, rd0, rd1, rd2, rd3, D2_2CD_C, D2_2CD_S);
   
   reg           p1a0, p1a1, p1a2, p1a3, p1b0, p1b1, p1b2, p1b3, p1c0, p1c1, p1c2, p1c3, p1d0, p1d1, p1d2, p1d3;  // pipeline register between stages 1&2
   reg  [11:0]   p1_D2_2CD_S;    
   reg  [12:7]   p1_D2_2CD_C;
      
   always @(posedge Clock)
   begin

      p1_D2_2CD_C  <= D2_2CD_C ;      p1_D2_2CD_S  <= D2_2CD_S ;

      p1a0 <= ra0;      p1a1 <= ra1;      p1a2 <= ra2;      p1a3 <= ra3;
           p1b0 <= rb0;      p1b1 <= rb1;      p1b2 <= rb2;      p1b3 <= rb3;
      p1c0 <= rc0;      p1c1 <= rc1;      p1c2 <= rc2;      p1c3 <= rc3;
		     p1d0 <= rd0;      p1d1 <= rd1;      p1d2 <= rd2;      p1d3 <= rd3;

   end      

////////////////////////////////////////////
// Stage #2
   wire [11:7] s2_prev_S = p1_D2_2CD_S[11:7];
   wire [12:7] s2_prev_C = p1_D2_2CD_C[12:7];
   wire [16:9] C2_2BD_C;   
	wire [15:7] C2_2BD_S;

   C2_2BD U_C2_2BD (p1b0, p1b1, p1b2, p1b3, p1c0, p1c1, p1c2, p1c3, p1d0, p1d1, p1d2, p1d3, s2_prev_S, s2_prev_C, C2_2BD_C, C2_2BD_S);

   reg          p2a0, p2a1, p2a2, p2a3, p2b0, p2b1, p2b2, p2b3, p2c0, p2c1, p2c2, p2c3, p2d0, p2d1, p2d2, p2d3;    // pipeline register between stages 2&3
   reg  [16:9]  p2_result_C;
	reg  [15:9]  p2_result_S;
   reg  [8:0]   p2_square;

   always @(posedge Clock)
   begin

      p2a0 <= p1a0;      p2a1 <= p1a1;      p2a2 <= p1a2;      p2a3 <= p1a3;
         p2b0 <= p1b0;      p2b1 <= p1b1;      p2b2 <= p1b2;      p2b3 <= p1b3;
      p2c0 <= p1c0;      p2c1 <= p1c1;      p2c2 <= p1c2;      p2c3 <= p2c3;
		   p2d0 <= p1d0;      p2d2 <= p1d2;      p2d2 <= p1d2;      p2d3 <= p1d3;
			
      p2_result_C <= C2_2BD_C ;     
		p2_result_S[15:9] <= C2_2BD_S[15:9];
      p2_square[8:7] <= C2_2BD_S[8:7];
      p2_square[6:0] <= p1_D2_2CD_S[6:0];
		
   end      

////////////////////////////////////////////
// Stage #3
   wire [16:9]  s3_prev_S = p2_result_S;
   wire [15:9]  s3_prev_C = p2_result_C;
   wire [20:13] AD2_2BC_C;   
	wire [20:9]  AD2_2BC_S;

   AD2_2BC U_AD2_2BC (p2a0, p2a1, p2a2, p2a3, p2b0, p2b1, p2b2, p2b3, p2c0, p2c1, p2c2, p2c3, p2d0, p2d1, p2d2, p2d3, s3_prev_S, s3_prev_C, AD2_2BC_C, AD2_2BC_S);

   reg         p3a0, p3a1, p3a2, p3a3, p3b0, p3b1, p3b2, p3b3, p3c0, p3c1, p3c2, p3c3;       // pipeline register between stages 3&4
   reg [20:13] p3_result_C, p3_result_S;
	reg [12:0]  p3_square;

   always @(posedge Clock)
   begin  
		
		p3a0 <= p2a0;		p3a1 <= p2a1;		p3a2 <= p2a2;		p3a3 <= p2a3;
			p3b0 <= p2b0;		p3b1 <= p2b1;		p3b2 <= p2b2;		p3b3 <= p2b3;
		p3c0 <= p2c0;		p3c1 <= p2c1;		p3c2 <= p2c2;		p3c3 <= p2c3;
		
      p3_result_C <= AD2_2BC_C;      
		p3_result_S[20:13] <= AD2_2BC_S[20:13];
      p3_square[12:9] <= AD2_2BC_S[12:9];  
		p3_square[8:0] <= p2_square[8:0];
		
   end      

////////////////////////////////////////////
// Stage #4
	wire [20:13] s4_prev_S = p3_result_S;
	wire [20:13] s4_prev_C = p3_result_C;
	wire [24:17] B2_2AC_C;
	wire [24:13] B2_2AC_S;
	
	B2_2AC U_B2_2AC (p3a0, p3a1, p3a2, p3a3, p3b0, p3b1, p3b2, p3b3, p3c0, p3c1, p3c2, p3c3, s4_prev_C, s4_prev_S, B2_2AC_C, B2_2AC_S);
	
	reg         p4a0, p4a1, p4a2, p4a3, p4b0, p4b1, p4b2, p4b3;
	reg [24:17] p4_result_C, p4_result_S;
	reg [16:0]  p4_square;
	 
	always @(posedge Clock)
	begin
		
		p4a0 <= p3a0;		p4a1 <= p3a1;		p4a2 <= p3a2;		p4a3 <= p3a3;
			p4b0 <= p3b0;		p4b1 <= p3b1;		p4b2 <= p3b2;		p4b3<= p3b3;
		
		p4_result_C <= B2_2AC_C;
		p4_result_S[24:17] <= B2_2AC_S[24:17];
		p4_square[16:13] <= B2_2AC_S[16:13];
		p4_square[12:0] <= p3_square[12:0];
		
	end

////////////////////////////////////////////
// Stage #5	
	wire [24:17] s5_prev_S = p4_result_S;
	wire [24:17] s5_prev_C = p4_result_C;
	wire [31:21] A2_2AB_C;
	wire [30:17] A2_2AB_S;
	
	A2_2AB U_A2_2AB (p4a0, p4a1, p4a2, p4a3, p4b0, p4b1, p4b2, p4b3, s5_prev_C, s5_prev_S, s5_prev_C, A2_2AB_C, A2_2AB_S);
	
	reg [31:21] p5_result_C;
	reg [30:21] p5_result_S;
	reg [20:0]  p5_square;
	
	always @(posedge Clock)
	begin
	
		p5_result_C <= A2_2AB_C;
		p5_result_S[30:21] <= A2_2AB_S[30:21];
		p5_square[20:17] <= A2_2AB_S[20:17];
		p5_square[16:0] <= p4_square[16:0];
		
	end
	
////////////////////////////////////////////
// Stage #6
   
   always @(posedge Clock)
   begin
            square[20:0]  <= p5_square;
            square[31:21] <= p5_result_C[31:21] + p5_result_S[30:21];
   end
   
endmodule
