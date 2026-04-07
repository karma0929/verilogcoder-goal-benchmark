module prob155_power_top (aaah,
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
 wire _15_;
 wire _18_;
 wire _19_;
 wire _20_;
 wire _21_;
 wire _22_;
 wire _23_;
 wire _24_;
 wire _25_;
 wire _26_;
 wire _27_;
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
 wire net6;
 wire net1;
 wire net2;
 wire net3;
 wire net4;
 wire net7;
 wire \dut.dead ;
 wire \dut.digging_r ;
 wire \dut.dir ;
 wire \dut.fall_counter[0] ;
 wire \dut.fall_counter[1] ;
 wire \dut.fall_counter[2] ;
 wire \dut.fall_counter[3] ;
 wire \dut.fall_counter[4] ;
 wire \dut.falling ;
 wire net5;
 wire net8;
 wire net9;
 wire clknet_0_clk;
 wire clknet_1_0__leaf_clk;
 wire clknet_1_1__leaf_clk;

 INV_X1 _53_ (.A(net5),
    .ZN(_15_));
 OR3_X4 _56_ (.A1(\dut.digging_r ),
    .A2(\dut.falling ),
    .A3(\dut.dead ),
    .ZN(_18_));
 NOR3_X4 _57_ (.A1(net4),
    .A2(_15_),
    .A3(_18_),
    .ZN(_19_));
 AOI21_X2 _58_ (.A(\dut.dir ),
    .B1(net2),
    .B2(_19_),
    .ZN(_20_));
 AND2_X1 _59_ (.A1(net3),
    .A2(_19_),
    .ZN(_21_));
 AOI21_X2 _60_ (.A(_20_),
    .B1(_21_),
    .B2(\dut.dir ),
    .ZN(_08_));
 INV_X1 _61_ (.A(\dut.falling ),
    .ZN(_22_));
 NAND3_X1 _62_ (.A1(_22_),
    .A2(net4),
    .A3(net5),
    .ZN(_23_));
 XOR2_X1 _63_ (.A(\dut.falling ),
    .B(net5),
    .Z(_24_));
 NAND2_X1 _64_ (.A1(\dut.digging_r ),
    .A2(_24_),
    .ZN(_25_));
 AOI21_X1 _65_ (.A(\dut.dead ),
    .B1(_23_),
    .B2(_25_),
    .ZN(_07_));
 NOR2_X1 _66_ (.A1(\dut.dead ),
    .A2(net5),
    .ZN(_01_));
 NOR2_X1 _67_ (.A1(\dut.dir ),
    .A2(_18_),
    .ZN(net8));
 INV_X1 _68_ (.A(\dut.dir ),
    .ZN(_26_));
 NOR2_X1 _69_ (.A1(_26_),
    .A2(_18_),
    .ZN(net9));
 NOR2_X1 _70_ (.A1(_22_),
    .A2(\dut.dead ),
    .ZN(net6));
 INV_X1 _71_ (.A(\dut.dead ),
    .ZN(_27_));
 AND2_X1 _72_ (.A1(\dut.digging_r ),
    .A2(_27_),
    .ZN(net7));
 OAI21_X1 _75_ (.A(\dut.fall_counter[4] ),
    .B1(\dut.fall_counter[3] ),
    .B2(\dut.fall_counter[2] ),
    .ZN(_30_));
 NAND2_X1 _76_ (.A1(\dut.falling ),
    .A2(net5),
    .ZN(_31_));
 OAI21_X1 _77_ (.A(_27_),
    .B1(_30_),
    .B2(_31_),
    .ZN(_00_));
 INV_X1 _78_ (.A(net1),
    .ZN(_06_));
 AND3_X1 _79_ (.A1(\dut.fall_counter[3] ),
    .A2(\dut.fall_counter[2] ),
    .A3(_05_),
    .ZN(_32_));
 OAI21_X1 _80_ (.A(\dut.falling ),
    .B1(_32_),
    .B2(\dut.fall_counter[4] ),
    .ZN(_33_));
 INV_X1 _81_ (.A(_33_),
    .ZN(_09_));
 MUX2_X1 _82_ (.A(\dut.fall_counter[1] ),
    .B(_04_),
    .S(_30_),
    .Z(_34_));
 AND2_X1 _83_ (.A1(\dut.falling ),
    .A2(_34_),
    .ZN(_10_));
 MUX2_X1 _84_ (.A(\dut.fall_counter[0] ),
    .B(_02_),
    .S(_30_),
    .Z(_35_));
 AND2_X1 _85_ (.A1(\dut.falling ),
    .A2(_35_),
    .ZN(_11_));
 INV_X1 _86_ (.A(\dut.fall_counter[4] ),
    .ZN(_36_));
 NAND4_X1 _87_ (.A1(\dut.fall_counter[0] ),
    .A2(\dut.fall_counter[1] ),
    .A3(_36_),
    .A4(\dut.fall_counter[2] ),
    .ZN(_37_));
 XOR2_X1 _88_ (.A(\dut.fall_counter[3] ),
    .B(_37_),
    .Z(_38_));
 NOR2_X1 _89_ (.A1(_22_),
    .A2(_38_),
    .ZN(_12_));
 NAND2_X1 _90_ (.A1(\dut.fall_counter[4] ),
    .A2(\dut.fall_counter[3] ),
    .ZN(_39_));
 AOI21_X1 _91_ (.A(\dut.fall_counter[2] ),
    .B1(_05_),
    .B2(_39_),
    .ZN(_40_));
 NAND2_X1 _92_ (.A1(\dut.fall_counter[2] ),
    .A2(_05_),
    .ZN(_41_));
 OAI21_X1 _93_ (.A(\dut.falling ),
    .B1(_41_),
    .B2(\dut.fall_counter[4] ),
    .ZN(_42_));
 NOR2_X1 _94_ (.A1(_40_),
    .A2(_42_),
    .ZN(_13_));
 HA_X1 _95_ (.A(_02_),
    .B(_50_),
    .CO(_03_),
    .S(_04_));
 HA_X1 _96_ (.A(\dut.fall_counter[0] ),
    .B(\dut.fall_counter[1] ),
    .CO(_05_),
    .S(_51_));
 CLKBUF_X3 clkbuf_0_clk (.A(clk),
    .Z(clknet_0_clk));
 CLKBUF_X3 clkbuf_1_0__f_clk (.A(clknet_0_clk),
    .Z(clknet_1_0__leaf_clk));
 CLKBUF_X3 clkbuf_1_1__f_clk (.A(clknet_0_clk),
    .Z(clknet_1_1__leaf_clk));
 CLKBUF_X1 clkload0 (.A(clknet_1_1__leaf_clk));
 DFFR_X1 \dut.dead$_DFF_PP0_  (.D(_00_),
    .RN(_06_),
    .CK(clknet_1_1__leaf_clk),
    .Q(\dut.dead ),
    .QN(_47_));
 DFFR_X1 \dut.digging_r$_DFFE_PP0P_  (.D(_07_),
    .RN(_06_),
    .CK(clknet_1_0__leaf_clk),
    .Q(\dut.digging_r ),
    .QN(_49_));
 DFFR_X1 \dut.dir$_DFFE_PP0P_  (.D(_08_),
    .RN(_06_),
    .CK(clknet_1_1__leaf_clk),
    .Q(\dut.dir ),
    .QN(_46_));
 DFF_X1 \dut.fall_counter[0]$_SDFFE_PN0N_  (.D(_11_),
    .CK(clknet_1_1__leaf_clk),
    .Q(\dut.fall_counter[0] ),
    .QN(_02_));
 DFF_X1 \dut.fall_counter[1]$_SDFFE_PN0N_  (.D(_10_),
    .CK(clknet_1_1__leaf_clk),
    .Q(\dut.fall_counter[1] ),
    .QN(_50_));
 DFF_X1 \dut.fall_counter[2]$_SDFFE_PN0N_  (.D(_13_),
    .CK(clknet_1_0__leaf_clk),
    .Q(\dut.fall_counter[2] ),
    .QN(_43_));
 DFF_X1 \dut.fall_counter[3]$_SDFFE_PN0N_  (.D(_12_),
    .CK(clknet_1_0__leaf_clk),
    .Q(\dut.fall_counter[3] ),
    .QN(_44_));
 DFF_X1 \dut.fall_counter[4]$_SDFFE_PN0N_  (.D(_09_),
    .CK(clknet_1_0__leaf_clk),
    .Q(\dut.fall_counter[4] ),
    .QN(_45_));
 DFFR_X1 \dut.falling$_DFF_PP0_  (.D(_01_),
    .RN(_06_),
    .CK(clknet_1_0__leaf_clk),
    .Q(\dut.falling ),
    .QN(_48_));
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
