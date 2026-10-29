//===============================================================================
// Vivado RAM for the Basys 3 project
//
// Replaces the Gowin RAM IP (Gowin_SP1..SP5, Gowin_DPB1) used by the core, with the
// same module names and ports. One-cycle read, output held during a write. reset and
// oce are not used.
//===============================================================================

module xilinx_sp_ram #(parameter AW = 8, parameter DW = 8)
(
    output reg [DW-1:0] dout,
    input clk,
    input ce,
    input wre,
    input [AW-1:0] ad,
    input [DW-1:0] din
);

    reg [DW-1:0] mem [0:(1<<AW)-1];

    always @(posedge clk) begin
        if (ce) begin
            if (wre)
                mem[ad] <= din;
            else
                dout <= mem[ad];
        end
    end

endmodule

/////////////////////////////////////////////////////////////////////

module Gowin_SP1 (dout, clk, oce, ce, reset, wre, ad, din);
    output [7:0] dout;
    input clk, oce, ce, reset, wre;
    input [5:0] ad;
    input [7:0] din;

    xilinx_sp_ram #(6, 8) sp (
        .dout(dout),
        .clk(clk),
        .ce(ce),
        .wre(wre),
        .ad(ad),
        .din(din)
    );
endmodule

module Gowin_SP2 (dout, clk, oce, ce, reset, wre, ad, din);
    output [7:0] dout;
    input clk, oce, ce, reset, wre;
    input [9:0] ad;
    input [7:0] din;

    xilinx_sp_ram #(10, 8) sp (
        .dout(dout),
        .clk(clk),
        .ce(ce),
        .wre(wre),
        .ad(ad),
        .din(din)
    );
endmodule

module Gowin_SP3 (dout, clk, oce, ce, reset, wre, ad, din);
    output [5:0] dout;
    input clk, oce, ce, reset, wre;
    input [7:0] ad;
    input [5:0] din;

    xilinx_sp_ram #(8, 6) sp (
        .dout(dout),
        .clk(clk),
        .ce(ce),
        .wre(wre),
        .ad(ad),
        .din(din)
    );
endmodule

module Gowin_SP4 (dout, clk, oce, ce, reset, wre, ad, din);
    output [8:0] dout;
    input clk, oce, ce, reset, wre;
    input [5:0] ad;
    input [8:0] din;

    xilinx_sp_ram #(6, 9) sp (
        .dout(dout),
        .clk(clk),
        .ce(ce),
        .wre(wre),
        .ad(ad),
        .din(din)
    );
endmodule

module Gowin_SP5 (dout, clk, oce, ce, reset, wre, ad, din);
    output [3:0] dout;
    input clk, oce, ce, reset, wre;
    input [7:0] ad;
    input [3:0] din;

    xilinx_sp_ram #(8, 4) sp (
        .dout(dout),
        .clk(clk),
        .ce(ce),
        .wre(wre),
        .ad(ad),
        .din(din)
    );
endmodule

/////////////////////////////////////////////////////////////////////

module Gowin_DPB1 (douta, doutb, clka, ocea, cea, reseta, wrea, clkb, oceb, ceb, resetb,
    wreb, ada, dina, adb, dinb);
    output reg [7:0] douta;
    output reg [7:0] doutb;
    input clka, ocea, cea, reseta, wrea;
    input clkb, oceb, ceb, resetb, wreb;
    input [9:0] ada, adb;
    input [7:0] dina, dinb;

    reg [7:0] mem [0:1023];

    always @(posedge clka) begin
        if (cea) begin
            if (wrea)
                mem[ada] <= dina;
            else
                douta <= mem[ada];
        end
    end

    always @(posedge clkb) begin
        if (ceb) begin
            if (wreb)
                mem[adb] <= dinb;
            else
                doutb <= mem[adb];
        end
    end

endmodule
