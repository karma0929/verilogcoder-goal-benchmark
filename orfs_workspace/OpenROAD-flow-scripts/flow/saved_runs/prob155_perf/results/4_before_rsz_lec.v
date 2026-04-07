module prob155_perf_top (aaah,
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

 wire _000_;
 wire _001_;
 wire _002_;
 wire _003_;
 wire _004_;
 wire _005_;
 wire _006_;
 wire _007_;
 wire _008_;
 wire _009_;
 wire _010_;
 wire _011_;
 wire _012_;
 wire _013_;
 wire _014_;
 wire _015_;
 wire _016_;
 wire _018_;
 wire _019_;
 wire _021_;
 wire _023_;
 wire _024_;
 wire _025_;
 wire _028_;
 wire _029_;
 wire _030_;
 wire _031_;
 wire _032_;
 wire _033_;
 wire _034_;
 wire _035_;
 wire _036_;
 wire _037_;
 wire _038_;
 wire _039_;
 wire _040_;
 wire _041_;
 wire _042_;
 wire _043_;
 wire _044_;
 wire _045_;
 wire _046_;
 wire _047_;
 wire _048_;
 wire _049_;
 wire _050_;
 wire _051_;
 wire _052_;
 wire _053_;
 wire _054_;
 wire _055_;
 wire _056_;
 wire _057_;
 wire _058_;
 wire _059_;
 wire _060_;
 wire _061_;
 wire _062_;
 wire _063_;
 wire _064_;
 wire _065_;
 wire _066_;
 wire _067_;
 wire _068_;
 wire _069_;
 wire _070_;
 wire net6;
 wire net1;
 wire net2;
 wire net3;
 wire net4;
 wire net7;
 wire \dut.fall_counter[0] ;
 wire \dut.fall_counter[1] ;
 wire \dut.fall_counter[2] ;
 wire \dut.fall_counter[3] ;
 wire \dut.fall_counter[4] ;
 wire \dut.next[0] ;
 wire \dut.next[1] ;
 wire \dut.next[2] ;
 wire \dut.next[3] ;
 wire \dut.next[4] ;
 wire \dut.next[5] ;
 wire \dut.state[2] ;
 wire \dut.state[3] ;
 wire \dut.state[4] ;
 wire \dut.state[5] ;
 wire \dut.state[6] ;
 wire net5;
 wire net8;
 wire net9;
 wire clknet_0_clk;
 wire clknet_1_0__leaf_clk;
 wire clknet_1_1__leaf_clk;

 INV_X1 _072_ (.A(\dut.state[2] ),
    .ZN(_018_));
 AND2_X1 _073_ (.A1(_018_),
    .A2(_003_),
    .ZN(_019_));
 OAI21_X2 _075_ (.A(\dut.fall_counter[4] ),
    .B1(\dut.fall_counter[2] ),
    .B2(\dut.fall_counter[3] ),
    .ZN(_021_));
 INV_X1 _077_ (.A(net9),
    .ZN(_023_));
 NAND3_X1 _078_ (.A1(net5),
    .A2(_023_),
    .A3(_002_),
    .ZN(_024_));
 NOR3_X1 _079_ (.A1(_019_),
    .A2(_021_),
    .A3(_024_),
    .ZN(_025_));
 OR2_X1 _081_ (.A1(\dut.state[3] ),
    .A2(\dut.state[2] ),
    .ZN(net6));
 OR4_X4 _083_ (.A1(\dut.state[5] ),
    .A2(\dut.state[4] ),
    .A3(net9),
    .A4(net8),
    .ZN(_028_));
 NOR2_X1 _084_ (.A1(net6),
    .A2(_028_),
    .ZN(_029_));
 MUX2_X1 _085_ (.A(_025_),
    .B(\dut.state[6] ),
    .S(_029_),
    .Z(_009_));
 INV_X1 _086_ (.A(net5),
    .ZN(_030_));
 INV_X1 _087_ (.A(net4),
    .ZN(_031_));
 INV_X1 _088_ (.A(\dut.state[4] ),
    .ZN(_032_));
 INV_X1 _089_ (.A(\dut.state[3] ),
    .ZN(_033_));
 NAND4_X1 _090_ (.A1(\dut.state[5] ),
    .A2(_032_),
    .A3(_033_),
    .A4(_001_),
    .ZN(_034_));
 MUX2_X1 _091_ (.A(_031_),
    .B(_034_),
    .S(_023_),
    .Z(_035_));
 NOR3_X1 _092_ (.A1(_030_),
    .A2(net8),
    .A3(_035_),
    .ZN(\dut.next[5] ));
 NOR3_X1 _093_ (.A1(_032_),
    .A2(net8),
    .A3(net6),
    .ZN(_036_));
 AOI22_X1 _094_ (.A1(net4),
    .A2(net8),
    .B1(_000_),
    .B2(_036_),
    .ZN(_037_));
 NOR2_X1 _095_ (.A1(_030_),
    .A2(_037_),
    .ZN(\dut.next[4] ));
 AOI21_X1 _096_ (.A(\dut.state[3] ),
    .B1(_032_),
    .B2(\dut.state[5] ),
    .ZN(_038_));
 OAI21_X1 _097_ (.A(_023_),
    .B1(\dut.state[2] ),
    .B2(_038_),
    .ZN(_039_));
 AND3_X1 _098_ (.A1(_030_),
    .A2(_002_),
    .A3(_039_),
    .ZN(\dut.next[3] ));
 OAI21_X1 _099_ (.A(_018_),
    .B1(\dut.state[3] ),
    .B2(_032_),
    .ZN(_040_));
 AOI21_X1 _100_ (.A(net8),
    .B1(_000_),
    .B2(_040_),
    .ZN(_041_));
 NOR2_X1 _101_ (.A1(net5),
    .A2(_041_),
    .ZN(\dut.next[2] ));
 NAND2_X1 _102_ (.A1(\dut.state[3] ),
    .A2(_001_),
    .ZN(_042_));
 INV_X1 _103_ (.A(net8),
    .ZN(_043_));
 NAND4_X1 _104_ (.A1(net5),
    .A2(_023_),
    .A3(_043_),
    .A4(_021_),
    .ZN(_044_));
 NAND2_X1 _105_ (.A1(net5),
    .A2(_031_),
    .ZN(_045_));
 NOR3_X1 _106_ (.A1(_023_),
    .A2(net8),
    .A3(net3),
    .ZN(_046_));
 AOI21_X1 _107_ (.A(_046_),
    .B1(net2),
    .B2(net8),
    .ZN(_047_));
 OAI22_X1 _108_ (.A1(_042_),
    .A2(_044_),
    .B1(_045_),
    .B2(_047_),
    .ZN(\dut.next[1] ));
 OR2_X1 _109_ (.A1(_018_),
    .A2(_044_),
    .ZN(_048_));
 NOR2_X4 _110_ (.A1(\dut.state[6] ),
    .A2(_028_),
    .ZN(_049_));
 NAND2_X2 _111_ (.A1(_003_),
    .A2(_049_),
    .ZN(_050_));
 NAND2_X1 _112_ (.A1(net9),
    .A2(net3),
    .ZN(_051_));
 MUX2_X1 _113_ (.A(net2),
    .B(_051_),
    .S(_043_),
    .Z(_052_));
 OAI221_X2 _114_ (.A(_048_),
    .B1(_050_),
    .B2(\dut.state[2] ),
    .C1(_052_),
    .C2(_045_),
    .ZN(\dut.next[0] ));
 OR2_X1 _115_ (.A1(\dut.state[5] ),
    .A2(\dut.state[4] ),
    .ZN(net7));
 INV_X1 _116_ (.A(net1),
    .ZN(_008_));
 XOR2_X1 _117_ (.A(\dut.state[3] ),
    .B(\dut.state[2] ),
    .Z(_053_));
 NAND2_X2 _118_ (.A1(_049_),
    .A2(_053_),
    .ZN(_054_));
 INV_X1 _119_ (.A(\dut.fall_counter[4] ),
    .ZN(_055_));
 NAND4_X1 _120_ (.A1(\dut.fall_counter[2] ),
    .A2(_055_),
    .A3(\dut.fall_counter[1] ),
    .A4(\dut.fall_counter[0] ),
    .ZN(_056_));
 XOR2_X1 _121_ (.A(\dut.fall_counter[3] ),
    .B(_056_),
    .Z(_057_));
 NOR2_X1 _122_ (.A1(_054_),
    .A2(_057_),
    .ZN(_010_));
 INV_X1 _123_ (.A(\dut.fall_counter[2] ),
    .ZN(_058_));
 NAND3_X1 _124_ (.A1(_058_),
    .A2(_007_),
    .A3(_021_),
    .ZN(_059_));
 INV_X1 _125_ (.A(_007_),
    .ZN(_060_));
 OAI21_X1 _126_ (.A(\dut.fall_counter[2] ),
    .B1(\dut.fall_counter[4] ),
    .B2(_060_),
    .ZN(_061_));
 AOI21_X2 _127_ (.A(_054_),
    .B1(_059_),
    .B2(_061_),
    .ZN(_011_));
 MUX2_X1 _128_ (.A(\dut.fall_counter[1] ),
    .B(_006_),
    .S(_021_),
    .Z(_062_));
 AND3_X1 _129_ (.A1(_049_),
    .A2(_053_),
    .A3(_062_),
    .ZN(_012_));
 MUX2_X1 _130_ (.A(\dut.fall_counter[0] ),
    .B(_004_),
    .S(_021_),
    .Z(_015_));
 AND3_X1 _131_ (.A1(_049_),
    .A2(_053_),
    .A3(_015_),
    .ZN(_013_));
 NAND3_X1 _132_ (.A1(\dut.fall_counter[3] ),
    .A2(\dut.fall_counter[2] ),
    .A3(_007_),
    .ZN(_016_));
 AOI21_X2 _133_ (.A(_054_),
    .B1(_016_),
    .B2(_055_),
    .ZN(_014_));
 HA_X1 _134_ (.A(_004_),
    .B(_069_),
    .CO(_005_),
    .S(_006_));
 HA_X1 _135_ (.A(\dut.fall_counter[0] ),
    .B(\dut.fall_counter[1] ),
    .CO(_007_),
    .S(_070_));
 CLKBUF_X3 clkbuf_0_clk (.A(clk),
    .Z(clknet_0_clk));
 CLKBUF_X3 clkbuf_1_0__f_clk (.A(clknet_0_clk),
    .Z(clknet_1_0__leaf_clk));
 CLKBUF_X3 clkbuf_1_1__f_clk (.A(clknet_0_clk),
    .Z(clknet_1_1__leaf_clk));
 INV_X1 clkload0 (.A(clknet_1_0__leaf_clk));
 DFF_X1 \dut.fall_counter[0]$_SDFFE_PN0N_  (.D(_013_),
    .CK(clknet_1_0__leaf_clk),
    .Q(\dut.fall_counter[0] ),
    .QN(_004_));
 DFF_X1 \dut.fall_counter[1]$_SDFFE_PN0N_  (.D(_012_),
    .CK(clknet_1_0__leaf_clk),
    .Q(\dut.fall_counter[1] ),
    .QN(_069_));
 DFF_X1 \dut.fall_counter[2]$_SDFFE_PN0N_  (.D(_011_),
    .CK(clknet_1_0__leaf_clk),
    .Q(\dut.fall_counter[2] ),
    .QN(_065_));
 DFF_X1 \dut.fall_counter[3]$_SDFFE_PN0N_  (.D(_010_),
    .CK(clknet_1_0__leaf_clk),
    .Q(\dut.fall_counter[3] ),
    .QN(_066_));
 DFF_X1 \dut.fall_counter[4]$_SDFFE_PN0N_  (.D(_014_),
    .CK(clknet_1_0__leaf_clk),
    .Q(\dut.fall_counter[4] ),
    .QN(_064_));
 DFFS_X1 \dut.state[0]$_DFF_PP1_  (.D(\dut.next[0] ),
    .SN(_008_),
    .CK(clknet_1_1__leaf_clk),
    .Q(net8),
    .QN(_002_));
 DFFR_X1 \dut.state[1]$_DFF_PP0_  (.D(\dut.next[1] ),
    .RN(_008_),
    .CK(clknet_1_1__leaf_clk),
    .Q(net9),
    .QN(_000_));
 DFFR_X1 \dut.state[2]$_DFF_PP0_  (.D(\dut.next[2] ),
    .RN(_008_),
    .CK(clknet_1_1__leaf_clk),
    .Q(\dut.state[2] ),
    .QN(_001_));
 DFFR_X1 \dut.state[3]$_DFF_PP0_  (.D(\dut.next[3] ),
    .RN(_008_),
    .CK(clknet_1_1__leaf_clk),
    .Q(\dut.state[3] ),
    .QN(_003_));
 DFFR_X1 \dut.state[4]$_DFF_PP0_  (.D(\dut.next[4] ),
    .RN(_008_),
    .CK(clknet_1_1__leaf_clk),
    .Q(\dut.state[4] ),
    .QN(_068_));
 DFFR_X1 \dut.state[5]$_DFF_PP0_  (.D(\dut.next[5] ),
    .RN(_008_),
    .CK(clknet_1_1__leaf_clk),
    .Q(\dut.state[5] ),
    .QN(_063_));
 DFFR_X1 \dut.state[6]$_DFFE_PP0P_  (.D(_009_),
    .RN(_008_),
    .CK(clknet_1_1__leaf_clk),
    .Q(\dut.state[6] ),
    .QN(_067_));
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
