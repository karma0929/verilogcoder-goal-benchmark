module prob155_area_top (aaah,
    areset,
    bump_left,
    bump_right,
    clk,
    dig,
    digging,
    ground,
    walk_left,
    walk_right);
 output aaah;
 input areset;
 input bump_left;
 input bump_right;
 input clk;
 input dig;
 output digging;
 input ground;
 output walk_left;
 output walk_right;

 wire _00_;
 wire _01_;
 wire _02_;
 wire _03_;
 wire _04_;
 wire _05_;
 wire _06_;
 wire _07_;
 wire _08_;
 wire _09_;
 wire _10_;
 wire _11_;
 wire _12_;
 wire _13_;
 wire _14_;
 wire _16_;
 wire _18_;
 wire _19_;
 wire _20_;
 wire _21_;
 wire _22_;
 wire _23_;
 wire _24_;
 wire _25_;
 wire _27_;
 wire _28_;
 wire _29_;
 wire _30_;
 wire _31_;
 wire _32_;
 wire _33_;
 wire _34_;
 wire _35_;
 wire _36_;
 wire _37_;
 wire _38_;
 wire _39_;
 wire _40_;
 wire _41_;
 wire _42_;
 wire _43_;
 wire _44_;
 wire _45_;
 wire _46_;
 wire _47_;
 wire _48_;
 wire _49_;
 wire _50_;
 wire _51_;
 wire _52_;
 wire net6;
 wire net1;
 wire net2;
 wire net3;
 wire net4;
 wire net7;
 wire \dut.dir ;
 wire \dut.fall_counter[0] ;
 wire \dut.fall_counter[1] ;
 wire \dut.fall_counter[2] ;
 wire \dut.fall_counter[3] ;
 wire \dut.fall_counter[4] ;
 wire \dut.mode[0] ;
 wire \dut.mode[3] ;
 wire net5;
 wire net8;
 wire net9;
 wire clknet_0_clk;
 wire clknet_1_0__leaf_clk;
 wire clknet_1_1__leaf_clk;

 NOR3_X4 _54_ (.A1(net7),
    .A2(net6),
    .A3(\dut.mode[3] ),
    .ZN(_16_));
 INV_X1 _56_ (.A(net5),
    .ZN(_18_));
 OAI21_X1 _57_ (.A(\dut.mode[0] ),
    .B1(net4),
    .B2(_18_),
    .ZN(_19_));
 AND3_X2 _58_ (.A1(net2),
    .A2(_16_),
    .A3(_19_),
    .ZN(_20_));
 INV_X1 _59_ (.A(net4),
    .ZN(_21_));
 AND3_X1 _60_ (.A1(net5),
    .A2(_21_),
    .A3(net3),
    .ZN(_22_));
 INV_X1 _61_ (.A(\dut.mode[0] ),
    .ZN(_23_));
 OAI21_X1 _62_ (.A(_16_),
    .B1(_22_),
    .B2(_23_),
    .ZN(_24_));
 MUX2_X2 _63_ (.A(_20_),
    .B(_24_),
    .S(\dut.dir ),
    .Z(_09_));
 NOR3_X1 _64_ (.A1(net7),
    .A2(\dut.mode[0] ),
    .A3(net6),
    .ZN(_25_));
 NOR2_X1 _65_ (.A1(net5),
    .A2(_25_),
    .ZN(_00_));
 OAI21_X4 _67_ (.A(\dut.fall_counter[4] ),
    .B1(\dut.fall_counter[3] ),
    .B2(\dut.fall_counter[2] ),
    .ZN(_27_));
 AOI22_X1 _68_ (.A1(\dut.mode[0] ),
    .A2(_21_),
    .B1(_27_),
    .B2(net6),
    .ZN(_28_));
 NOR2_X1 _69_ (.A1(_18_),
    .A2(_28_),
    .ZN(_01_));
 AOI21_X1 _70_ (.A(net7),
    .B1(\dut.mode[0] ),
    .B2(net4),
    .ZN(_29_));
 NOR2_X1 _71_ (.A1(_18_),
    .A2(_29_),
    .ZN(_02_));
 INV_X1 _72_ (.A(\dut.mode[3] ),
    .ZN(_30_));
 NAND2_X1 _73_ (.A1(net5),
    .A2(net6),
    .ZN(_31_));
 OAI21_X1 _74_ (.A(_30_),
    .B1(_27_),
    .B2(_31_),
    .ZN(_03_));
 NOR2_X1 _75_ (.A1(\dut.dir ),
    .A2(_23_),
    .ZN(net8));
 AND2_X1 _76_ (.A1(\dut.dir ),
    .A2(\dut.mode[0] ),
    .ZN(net9));
 INV_X1 _77_ (.A(net1),
    .ZN(_08_));
 AND3_X1 _78_ (.A1(\dut.fall_counter[2] ),
    .A2(\dut.fall_counter[3] ),
    .A3(_07_),
    .ZN(_32_));
 OAI21_X1 _79_ (.A(net6),
    .B1(_32_),
    .B2(\dut.fall_counter[4] ),
    .ZN(_33_));
 INV_X1 _80_ (.A(_33_),
    .ZN(_10_));
 NAND2_X1 _81_ (.A1(\dut.fall_counter[4] ),
    .A2(\dut.fall_counter[3] ),
    .ZN(_34_));
 AOI21_X1 _82_ (.A(\dut.fall_counter[2] ),
    .B1(_07_),
    .B2(_34_),
    .ZN(_35_));
 INV_X1 _83_ (.A(\dut.fall_counter[4] ),
    .ZN(_36_));
 NAND3_X1 _84_ (.A1(\dut.fall_counter[2] ),
    .A2(_36_),
    .A3(_07_),
    .ZN(_37_));
 NAND2_X1 _85_ (.A1(net6),
    .A2(_37_),
    .ZN(_38_));
 NOR2_X1 _86_ (.A1(_35_),
    .A2(_38_),
    .ZN(_11_));
 MUX2_X1 _87_ (.A(\dut.fall_counter[1] ),
    .B(_06_),
    .S(_27_),
    .Z(_39_));
 AND2_X1 _88_ (.A1(net6),
    .A2(_39_),
    .ZN(_12_));
 MUX2_X1 _89_ (.A(\dut.fall_counter[0] ),
    .B(_04_),
    .S(_27_),
    .Z(_40_));
 AND2_X1 _90_ (.A1(net6),
    .A2(_40_),
    .ZN(_13_));
 NAND4_X1 _91_ (.A1(\dut.fall_counter[1] ),
    .A2(\dut.fall_counter[2] ),
    .A3(_36_),
    .A4(\dut.fall_counter[0] ),
    .ZN(_41_));
 XNOR2_X1 _92_ (.A(\dut.fall_counter[3] ),
    .B(_41_),
    .ZN(_42_));
 AND2_X1 _93_ (.A1(net6),
    .A2(_42_),
    .ZN(_14_));
 HA_X1 _94_ (.A(_04_),
    .B(_51_),
    .CO(_05_),
    .S(_06_));
 HA_X1 _95_ (.A(\dut.fall_counter[0] ),
    .B(\dut.fall_counter[1] ),
    .CO(_07_),
    .S(_52_));
 CLKBUF_X3 clkbuf_0_clk (.A(clk),
    .Z(clknet_0_clk));
 CLKBUF_X3 clkbuf_1_0__f_clk (.A(clknet_0_clk),
    .Z(clknet_1_0__leaf_clk));
 CLKBUF_X3 clkbuf_1_1__f_clk (.A(clknet_0_clk),
    .Z(clknet_1_1__leaf_clk));
 INV_X1 clkload0 (.A(clknet_1_0__leaf_clk));
 DFFR_X1 \dut.dir$_DFFE_PP0P_  (.D(_09_),
    .RN(_08_),
    .CK(clknet_1_1__leaf_clk),
    .Q(\dut.dir ),
    .QN(_50_));
 DFF_X1 \dut.fall_counter[0]$_SDFFE_PN0N_  (.D(_13_),
    .CK(clknet_1_1__leaf_clk),
    .Q(\dut.fall_counter[0] ),
    .QN(_04_));
 DFF_X1 \dut.fall_counter[1]$_SDFFE_PN0N_  (.D(_12_),
    .CK(clknet_1_0__leaf_clk),
    .Q(\dut.fall_counter[1] ),
    .QN(_51_));
 DFF_X1 \dut.fall_counter[2]$_SDFFE_PN0N_  (.D(_11_),
    .CK(clknet_1_0__leaf_clk),
    .Q(\dut.fall_counter[2] ),
    .QN(_46_));
 DFF_X1 \dut.fall_counter[3]$_SDFFE_PN0N_  (.D(_14_),
    .CK(clknet_1_0__leaf_clk),
    .Q(\dut.fall_counter[3] ),
    .QN(_43_));
 DFF_X1 \dut.fall_counter[4]$_SDFFE_PN0N_  (.D(_10_),
    .CK(clknet_1_0__leaf_clk),
    .Q(\dut.fall_counter[4] ),
    .QN(_48_));
 DFFS_X1 \dut.mode[0]$_DFF_PP1_  (.D(_01_),
    .SN(_08_),
    .CK(clknet_1_1__leaf_clk),
    .Q(\dut.mode[0] ),
    .QN(_45_));
 DFFR_X1 \dut.mode[1]$_DFF_PP0_  (.D(_02_),
    .RN(_08_),
    .CK(clknet_1_1__leaf_clk),
    .Q(net7),
    .QN(_49_));
 DFFR_X1 \dut.mode[2]$_DFF_PP0_  (.D(_00_),
    .RN(_08_),
    .CK(clknet_1_1__leaf_clk),
    .Q(net6),
    .QN(_47_));
 DFFR_X1 \dut.mode[3]$_DFF_PP0_  (.D(_03_),
    .RN(_08_),
    .CK(clknet_1_1__leaf_clk),
    .Q(\dut.mode[3] ),
    .QN(_44_));
 BUF_X1 input1 (.A(areset),
    .Z(net1));
 BUF_X1 input2 (.A(bump_left),
    .Z(net2));
 BUF_X1 input3 (.A(bump_right),
    .Z(net3));
 BUF_X1 input4 (.A(dig),
    .Z(net4));
 BUF_X1 input5 (.A(ground),
    .Z(net5));
 BUF_X1 output6 (.A(net6),
    .Z(aaah));
 BUF_X1 output7 (.A(net7),
    .Z(digging));
 BUF_X1 output8 (.A(net8),
    .Z(walk_left));
 BUF_X1 output9 (.A(net9),
    .Z(walk_right));
endmodule
