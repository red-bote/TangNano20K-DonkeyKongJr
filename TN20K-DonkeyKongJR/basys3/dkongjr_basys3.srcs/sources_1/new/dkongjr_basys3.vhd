---------------------------------------------------------------------------------
-- Basys 3 top level for Donkey Kong Jr.
-- Source: TN20K-DonkeyKongJR.vhd by pinballwiz.org
--   (https://github.com/pinballwizz/TangNano20K-DonkeyKongJr). See that file for
--   its history.
-- Core: Katsumi Degawa, modified for Donkey Kong Jr. by gaz68
---------------------------------------------------------------------------------
--
-- 10/27/2026: initial Basys 3 release by Red~Bote
--
---------------------------------------------------------------------------------
-- License:
--  - Basys 3 changes: MIT (see LICENSE)
--  - Code from TN20K-DonkeyKongJR.vhd: no license stated
--  - Core (dkongjr_*.v): freeware for non-commercial use (Katsumi Degawa)
---------------------------------------------------------------------------------
--
-- Main features:
--  Connections:
--   VGA monitor, 31 kHz (scandoubler). 15 kHz RGB with sw13 up (not tested)
--   USB keyboard on the USB-HID host connector (MAME default keys)
--   Atari-type joystick on Pmod JXADC, pins 1/2/3/4/7 = right/left/down/up/jump
--   PmodAMP2 with speaker on Pmod JA, pins 1/2/4
--  Controls       keyboard       stick          button
--   move          arrows         stick
--   jump          Left Ctrl      fire
--   coin          5                             btnU, btnD
--   start1/2      1, 2                          btnL, btnR
--   reset                                       btnC
--  Switches: sw15 audio off, sw14 gain, sw13 15 kHz RGB, sw0-sw7 DIP
--  DIP bits: lives 1:0, bonus 3:2, coinage 6:4, cabinet 7, switch down = default
--  Clock: 1 MMCM, 24.576 MHz from 100 MHz, single clock domain
--
-- DIP values and other details: see basys3/README.md
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;

---------------------------------------------------------------------------------
entity dkongjr_basys3 is
port(
    clk         : in  std_logic;
    btnC        : in  std_logic;
    btnU        : in  std_logic;
    btnD        : in  std_logic;
    btnL        : in  std_logic;
    btnR        : in  std_logic;
    sw          : in  std_logic_vector(15 downto 0);
    vga_r       : out std_logic_vector(3 downto 0);
    vga_g       : out std_logic_vector(3 downto 0);
    vga_b       : out std_logic_vector(3 downto 0);
    hsync       : out std_logic;
    vsync       : out std_logic;
    ps2_clk     : in  std_logic;
    ps2_dat     : inout std_logic;
    JA          : out std_logic_vector(7 downto 0);
    JXADC       : in  std_logic_vector(4 downto 0);
    led         : out std_logic_vector(15 downto 0)
);
end dkongjr_basys3;

------------------------------------------------------------------------------
architecture struct of dkongjr_basys3 is

    signal clock_100       : std_logic;
    signal clock_25        : std_logic;
    signal clock_24        : std_logic;
    signal clock_12        : std_logic;
    signal clk_sys         : std_logic;
    signal locked          : std_logic;
    --
    signal video_r         : std_logic_vector(5 downto 0);
    signal video_g         : std_logic_vector(5 downto 0);
    signal video_b         : std_logic_vector(5 downto 0);
    --
    signal M_VIDEO_R       : std_logic_vector(2 downto 0);
    signal M_VIDEO_G       : std_logic_vector(2 downto 0);
    signal M_VIDEO_B       : std_logic_vector(2 downto 0);
    --
    signal M_HSYNC         : std_logic;
    signal M_VSYNC         : std_logic;
    --
    signal video_r_x2      : std_logic_vector(5 downto 0);
    signal video_g_x2      : std_logic_vector(5 downto 0);
    signal video_b_x2      : std_logic_vector(5 downto 0);
    --
    signal hsync_x2        : std_logic;
    signal vsync_x2        : std_logic;
    --
    signal h_blank         : std_logic;
    signal v_blank         : std_logic;
    --
    signal audio           : std_logic_vector( 7 downto 0);
    signal M_AUDIO         : std_logic;
    --
    signal reset           : std_logic;
    --
    signal kbd_intr        : std_logic;
    signal kbd_scancode    : std_logic_vector(7 downto 0);
    signal joy_BBBBFRLDU   : std_logic_vector(8 downto 0);
    signal ps2_clk_meta    : std_logic;
    signal ps2_clk_s       : std_logic;
    signal ps2_dat_meta    : std_logic;
    signal ps2_dat_s       : std_logic;
    signal kbd_joy         : std_logic_vector(8 downto 0);
    signal btn_meta        : std_logic_vector(3 downto 0);
    signal btn_s           : std_logic_vector(3 downto 0);
    signal jx_meta         : std_logic_vector(4 downto 0);
    signal jx_s            : std_logic_vector(4 downto 0);
    attribute ASYNC_REG    : string;
    attribute ASYNC_REG of btn_meta, btn_s, jx_meta, jx_s : signal is "TRUE";
    attribute ASYNC_REG of ps2_clk_meta, ps2_clk_s, ps2_dat_meta, ps2_dat_s : signal is "TRUE";
    --
    constant CLOCK_FREQ    : integer := 27E6;
    signal counter_clk     : std_logic_vector(25 downto 0);
    signal clock_4hz       : std_logic;
    signal AD              : std_logic_vector(15 downto 0);
    signal clk_12_en       : std_logic;
    signal clk12_cnt       : std_logic_vector(1 downto 0);
    signal dip_sw          : std_logic_vector(7 downto 0);
    signal scanlines       : std_logic_vector(1 downto 0);

---------------------------------------------------------------------------
begin

    reset <= btnC or (not locked);

---------------------------------------------------------------------------
    -- Clock
    clk_wiz_0 : entity work.clk_wiz_0
    port map (
        clk_in1  => clk,
        clk_out1 => clk_sys,
        locked   => locked
    );

---------------------------------------------------------------------------
    process(clk_sys)
    begin
        if rising_edge(clk_sys) then
            clk12_cnt <= clk12_cnt + 1;
            if clk12_cnt = "01" then
                clk_12_en <= '1';
            else
                clk_12_en <= '0';
            end if;
        end if;
    end process;
    clock_12 <= clk_12_en;

---------------------------------------------------------------------------
    -- Vivado rejects literals as actuals of Verilog ports, so they go through signals
    dip_sw    <= "10000000" xor sw(7 downto 0);
    scanlines <= "00";

---------------------------------------------------------------------------
    dkongjr : entity work.dkongjr_main
    generic map (
        WAV_AW => 16, -- full wave ROM address
        -- full sample lengths, last sample of each ROM slot
        WAV_WALK_CNT => 16#07FF#,
        WAV_JUMP_CNT => 16#1FFF#,
        WAV_LAND_CNT => 16#1FFF#,
        WAV_FALL_CNT => 16#4FFF#
    )
    port map (
        I_CLK_24576M   => clk_sys,
        I_RESETn       => not reset,
        I_U1           => not joy_BBBBFRLDU(0),    -- P1 up
        I_D1           => not joy_BBBBFRLDU(1),    -- P1 down
        I_L1           => not joy_BBBBFRLDU(2),    -- P1 left
        I_R1           => not joy_BBBBFRLDU(3),    -- P1 right
        I_J1           => not joy_BBBBFRLDU(4),    -- P1 jump
        I_S1           => not joy_BBBBFRLDU(5),    -- P1 start
        I_U2           => not joy_BBBBFRLDU(0),    -- P2 up
        I_D2           => not joy_BBBBFRLDU(1),    -- P2 down
        I_L2           => not joy_BBBBFRLDU(2),    -- P2 left
        I_R2           => not joy_BBBBFRLDU(3),    -- P2 right
        I_J2           => not joy_BBBBFRLDU(4),    -- P2 jump
        I_S2           => not joy_BBBBFRLDU(6),    -- P2 start
        I_C1           => joy_BBBBFRLDU(7),        -- Coin
        I_DIP_SW       => dip_sw,
        O_VGA_R        => M_VIDEO_R,
        O_VGA_G        => M_VIDEO_G,
        O_VGA_B        => M_VIDEO_B,
        O_VGA_H_SYNCn  => M_HSYNC,
        O_VGA_V_SYNCn  => M_VSYNC,
        O_H_BLANK      => h_blank,
        O_V_BLANK      => v_blank,
        O_SOUND_DAT    => audio,
        AD             => AD
    );

-----------------------------------------------------------------
    -- vga inputs
    -- No H/V blank gating, the core blanks via 1EF clear (H_BLANK cut the last tile column)
    video_r <= M_VIDEO_R & M_VIDEO_R;
    video_g <= M_VIDEO_G & M_VIDEO_G;
    video_b <= M_VIDEO_B & M_VIDEO_B;

-----------------------------------------------------------------
    -- scan doubler

    dblscan: entity work.scandoubler
    port map(
        clk_sys => clk_sys,
        scanlines => scanlines,
        r_in   => video_r,
        g_in   => video_g,
        b_in   => video_b,
        hs_in  => M_HSYNC,
        vs_in  => M_VSYNC,
        r_out  => video_r_x2,
        g_out  => video_g_x2,
        b_out  => video_b_x2,
        hs_out => hsync_x2,
        vs_out => vsync_x2
    );

-----------------------------------------------------------------
    -- vga outputs

    -- sw13 down: 31 kHz VGA (scandoubler), up: 15 kHz TV with composite sync on HS
    process(clk_sys)
    begin
        if rising_edge(clk_sys) then
            if sw(13) = '0' then
                vga_r <= video_r_x2(5 downto 2);
                vga_g <= video_g_x2(5 downto 2);
                vga_b <= video_b_x2(5 downto 2);
                hsync <= hsync_x2;
                vsync <= vsync_x2;
            else
                vga_r <= video_r(5 downto 2);
                vga_g <= video_g(5 downto 2);
                vga_b <= video_b(5 downto 2);
                hsync <= M_HSYNC and M_VSYNC;
                vsync <= '1';
            end if;
        end if;
    end process;

-----------------------------------------------------------------
    dac: entity work.dac
    port map (
        clk_i   => clk_sys,
        res_n_i => not reset,
        dac_i   => audio,
        dac_o   => M_AUDIO
    );

    JA(0) <= M_AUDIO;
    JA(1) <= not sw(14);    -- PmodAMP2 GAIN (JA2), active low: sw14 up = gain
    JA(2) <= '0';
    JA(3) <= not sw(15);    -- PmodAMP2 SHUTD (JA4), active low: sw15 up = shut down
    JA(7 downto 4) <= (others => '0');

-----------------------------------------------------------------
    -- get scancode from keyboard

    process(clk_sys)
    begin
        if rising_edge(clk_sys) then
            ps2_clk_meta <= ps2_clk;
            ps2_clk_s    <= ps2_clk_meta;
            ps2_dat_meta <= ps2_dat;
            ps2_dat_s    <= ps2_dat_meta;
        end if;
    end process;

    keyboard : entity work.io_ps2_keyboard
    port map (
        clk       => clk_sys,
        kbd_clk   => ps2_clk_s,
        kbd_dat   => ps2_dat_s,
        interrupt => kbd_intr,
        scancode  => kbd_scancode
    );

-----------------------------------------------------------------
    -- translate scancode to joystick

    joystick : entity work.kbd_joystick
    port map (
        clk           => clk_sys,
        kbdint        => kbd_intr,
        kbdscancode   => std_logic_vector(kbd_scancode),
        joy_BBBBFRLDU => kbd_joy
    );

-----------------------------------------------------------------
    -- buttons and JXADC joystick (active low, pins 1/2/3/4/7 = R/L/D/U/fire):
    -- 2-FF synchronizers, ORed with the keyboard
    process(clk_sys)
    begin
        if rising_edge(clk_sys) then
            btn_meta <= btnU & btnD & btnL & btnR;
            btn_s    <= btn_meta;
            jx_meta  <= JXADC;
            jx_s     <= jx_meta;
        end if;
    end process;

    joy_BBBBFRLDU(0) <= kbd_joy(0) or not jx_s(3); -- up
    joy_BBBBFRLDU(1) <= kbd_joy(1) or not jx_s(2); -- down
    joy_BBBBFRLDU(2) <= kbd_joy(2) or not jx_s(1); -- left
    joy_BBBBFRLDU(3) <= kbd_joy(3) or not jx_s(0); -- right
    joy_BBBBFRLDU(4) <= kbd_joy(4) or not jx_s(4); -- jump
    joy_BBBBFRLDU(5) <= kbd_joy(5) or btn_s(1); -- start 1: btnL
    joy_BBBBFRLDU(6) <= kbd_joy(6) or btn_s(0); -- start 2: btnR
    joy_BBBBFRLDU(7) <= kbd_joy(7) or btn_s(3) or btn_s(2); -- coin: btnU, btnD
    joy_BBBBFRLDU(8) <= kbd_joy(8);

-----------------------------------------------------------------
    -- debug

    led(15 downto 12) <= (others => '0');

    process(reset, clk_sys)
    begin
        if reset = '1' then
            clock_4hz <= '0';
            counter_clk <= (others => '0');
        else
            if rising_edge(clk_sys) then
                if counter_clk = CLOCK_FREQ/8 then
                    counter_clk <= (others => '0');
                    clock_4hz <= not clock_4hz;
                    led(11 downto 0) <= not AD(9 downto 4) & "000000";
                else
                    counter_clk <= counter_clk + 1;
                end if;
            end if;
        end if;
    end process;

------------------------------------------------------------------------
end struct;