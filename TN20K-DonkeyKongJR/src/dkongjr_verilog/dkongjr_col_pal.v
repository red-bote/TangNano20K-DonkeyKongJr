//===============================================================================
// FPGA DONKEY KONG   COLOR_PALETE(XILINX EDITION)
//
// Version : 3.00
//
// Copyright(c) 2003 - 2004 Katsumi Degawa , All rights reserved
//
// Important !
//
// This program is freeware for non-commercial use. 
// An author does no guarantee about this program.
// You can use this under your own risk.
//
// 2005- 2- 9 	The description of the ROM was changed.
//              Data on the ROM are initialized at the time of the start.            
//================================================================================

module dkongjr_col_pal
(
	input  CLK_24M,
	input  CLK_6M,
	input  CLK_12M,
	input  [5:0]I_VRAM_D,
	input  [5:0]I_OBJ_D,
	input  I_CMPBLKn,
	input  I_5H_Q6,I_5H_Q7,

	input  [7:0]I_CNF_A,
	input  [7:0]I_CNF_D,
	input  I_CNF_EN,
	input  I_WE2,
	input  I_WE3,

	output [2:0]O_R,
	output [2:0]O_G,
	output [1:0]O_B
);

//-------  PARTS 3ML ------------------------------------
wire   [5:0]W_3ML_Y = (~(I_OBJ_D[0]|I_OBJ_D[1])) ? I_VRAM_D: I_OBJ_D;

//-------  PARTS 1EF ------------------------------------
wire   [9:0]W_1EF_D = {I_5H_Q7,I_5H_Q6,W_3ML_Y[5:0],W_3ML_Y[0]|W_3ML_Y[1],I_CMPBLKn};
reg    [9:0]W_1EF_Q;
// CLK_6M rising edge as CLK_24M enable, synchronous self-reset (CMPBLKn | Q[0])
always@(posedge CLK_24M)
begin
   if(~CLK_6M & CLK_12M) W_1EF_Q <= I_CMPBLKn ? W_1EF_D : 10'h000;
end   

//-------  PARTS 2EF -------------------------------------------
wire   [7:0]W_PAL_AB = W_1EF_Q[9:2];
wire   ROM_CE = 1'b1;
wire   [7:0]W_2E_DO,W_2F_DO;

wire   [7:0]PAL_AD = I_CNF_EN ? I_CNF_A : W_PAL_AB[7:0];
wire   [7:0]PAL_DI = I_CNF_EN ? I_CNF_D : 8'h00 ;

//---------------------------------------------------------------
// palette PROMs read every CLK_24M cycle (was ~CLK_12M, same edge as CLK_6M)
pal2_rom PAL2(
   .clk(CLK_24M),
   .addr(PAL_AD),
   .data(W_2F_DO)
   );
//---------------------------------------------------------------
pal1_rom PAL1(
   .clk(CLK_24M),
   .addr(PAL_AD),
   .data(W_2E_DO)
   );
//---------------------------------------------------------------

assign {O_R, O_G, O_B} = {~W_2F_DO[3:0], ~W_2E_DO[3:0]};

//--------------------------------------------------
endmodule
//--------------------------------------------------