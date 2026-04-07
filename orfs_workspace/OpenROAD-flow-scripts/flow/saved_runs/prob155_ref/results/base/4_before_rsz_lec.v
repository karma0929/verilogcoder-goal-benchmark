module prob155_ref_top (aaah,
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
 wire _017_;
 wire _021_;
 wire _022_;
 wire _023_;
 wire _024_;
 wire _025_;
 wire _026_;
 wire _027_;
 wire _028_;
 wire _029_;
 wire _030_;
 wire _031_;
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
 wire \dut.state[1] ;
 wire \dut.state[2] ;
 wire \dut.state[5] ;
 wire \dut.state[6] ;
 wire net5;
 wire net8;
 wire net9;
 wire clknet_0_clk;
 wire clknet_1_0__leaf_clk;
 wire clknet_1_1__leaf_clk;

 NOR2_X1 _063_ (.A1(\dut.state[2] ),
    .A2(\dut.state[6] ),
    .ZN(_017_));
 NAND2_X1 _067_ (.A1(\dut.fall_counter[4] ),
    .A2(\dut.fall_counter[3] ),
    .ZN(_021_));
 AOI21_X1 _068_ (.A(\dut.fall_counter[2] ),
    .B1(_010_),
    .B2(_021_),
    .ZN(_022_));
 INV_X8 _069_ (.A(\dut.fall_counter[4] ),
    .ZN(_023_));
 AND3_X1 _070_ (.A1(\dut.fall_counter[2] ),
    .A2(_023_),
    .A3(_010_),
    .ZN(_024_));
 NOR3_X1 _071_ (.A1(_017_),
    .A2(_022_),
    .A3(_024_),
    .ZN(_013_));
 AOI21_X1 _072_ (.A(\dut.fall_counter[4] ),
    .B1(\dut.fall_counter[3] ),
    .B2(_010_),
    .ZN(_025_));
 AOI21_X1 _073_ (.A(\dut.fall_counter[2] ),
    .B1(\dut.fall_counter[4] ),
    .B2(\dut.fall_counter[3] ),
    .ZN(_026_));
 OAI21_X1 _074_ (.A(_006_),
    .B1(_025_),
    .B2(_026_),
    .ZN(_027_));
 NAND4_X1 _075_ (.A1(\dut.fall_counter[2] ),
    .A2(_023_),
    .A3(\dut.fall_counter[3] ),
    .A4(_010_),
    .ZN(_028_));
 OAI221_X1 _076_ (.A(_027_),
    .B1(_028_),
    .B2(_006_),
    .C1(\dut.state[2] ),
    .C2(\dut.state[6] ),
    .ZN(_029_));
 INV_X1 _077_ (.A(_029_),
    .ZN(_012_));
 INV_X1 _078_ (.A(_017_),
    .ZN(net6));
 OAI21_X2 _079_ (.A(\dut.fall_counter[4] ),
    .B1(\dut.fall_counter[3] ),
    .B2(\dut.fall_counter[2] ),
    .ZN(_030_));
 MUX2_X1 _080_ (.A(\dut.fall_counter[1] ),
    .B(_009_),
    .S(_030_),
    .Z(_031_));
 AND2_X1 _081_ (.A1(net6),
    .A2(_031_),
    .ZN(_014_));
 NOR3_X1 _083_ (.A1(\dut.state[1] ),
    .A2(net8),
    .A3(\dut.state[2] ),
    .ZN(_033_));
 NOR2_X1 _084_ (.A1(net5),
    .A2(_033_),
    .ZN(_000_));
 NOR3_X1 _085_ (.A1(\dut.state[5] ),
    .A2(net9),
    .A3(\dut.state[6] ),
    .ZN(_034_));
 NOR2_X1 _086_ (.A1(net5),
    .A2(_034_),
    .ZN(_001_));
 INV_X1 _087_ (.A(net5),
    .ZN(_035_));
 OR2_X1 _088_ (.A1(_035_),
    .A2(net4),
    .ZN(_036_));
 INV_X1 _089_ (.A(net2),
    .ZN(_037_));
 AOI22_X1 _090_ (.A1(net9),
    .A2(net3),
    .B1(_037_),
    .B2(net8),
    .ZN(_038_));
 NOR2_X1 _091_ (.A1(\dut.fall_counter[2] ),
    .A2(\dut.fall_counter[3] ),
    .ZN(_039_));
 INV_X1 _092_ (.A(_008_),
    .ZN(_040_));
 OR3_X2 _093_ (.A1(\dut.fall_counter[3] ),
    .A2(_040_),
    .A3(_006_),
    .ZN(_041_));
 AOI21_X2 _094_ (.A(_039_),
    .B1(_041_),
    .B2(_023_),
    .ZN(_042_));
 NAND2_X1 _095_ (.A1(net5),
    .A2(\dut.state[2] ),
    .ZN(_043_));
 OAI22_X1 _096_ (.A1(_036_),
    .A2(_038_),
    .B1(_042_),
    .B2(_043_),
    .ZN(_002_));
 AOI21_X1 _097_ (.A(\dut.state[1] ),
    .B1(net8),
    .B2(net4),
    .ZN(_044_));
 NOR2_X1 _098_ (.A1(_035_),
    .A2(_044_),
    .ZN(_003_));
 INV_X1 _099_ (.A(net3),
    .ZN(_045_));
 AOI22_X1 _100_ (.A1(net9),
    .A2(_045_),
    .B1(net2),
    .B2(net8),
    .ZN(_046_));
 NAND2_X1 _101_ (.A1(net5),
    .A2(\dut.state[6] ),
    .ZN(_047_));
 OAI22_X1 _102_ (.A1(_036_),
    .A2(_046_),
    .B1(_047_),
    .B2(_042_),
    .ZN(_004_));
 AOI21_X1 _103_ (.A(\dut.state[5] ),
    .B1(net9),
    .B2(net4),
    .ZN(_048_));
 NOR2_X1 _104_ (.A1(_035_),
    .A2(_048_),
    .ZN(_005_));
 OR2_X1 _105_ (.A1(\dut.state[1] ),
    .A2(\dut.state[5] ),
    .ZN(net7));
 INV_X1 _106_ (.A(net1),
    .ZN(_011_));
 INV_X1 _107_ (.A(_007_),
    .ZN(_049_));
 NAND4_X4 _108_ (.A1(\dut.fall_counter[2] ),
    .A2(_023_),
    .A3(\dut.fall_counter[1] ),
    .A4(_049_),
    .ZN(_050_));
 XOR2_X2 _109_ (.A(\dut.fall_counter[3] ),
    .B(_050_),
    .Z(_051_));
 NOR2_X2 _110_ (.A1(_017_),
    .A2(_051_),
    .ZN(_016_));
 MUX2_X1 _111_ (.A(\dut.fall_counter[0] ),
    .B(_007_),
    .S(_030_),
    .Z(_052_));
 AND2_X1 _112_ (.A1(net6),
    .A2(_052_),
    .ZN(_015_));
 HA_X1 _113_ (.A(_007_),
    .B(_061_),
    .CO(_008_),
    .S(_009_));
 HA_X1 _114_ (.A(\dut.fall_counter[0] ),
    .B(\dut.fall_counter[1] ),
    .CO(_010_),
    .S(_062_));
 CLKBUF_X3 clkbuf_0_clk (.A(clk),
    .Z(clknet_0_clk));
 CLKBUF_X3 clkbuf_1_0__f_clk (.A(clknet_0_clk),
    .Z(clknet_1_0__leaf_clk));
 CLKBUF_X3 clkbuf_1_1__f_clk (.A(clknet_0_clk),
    .Z(clknet_1_1__leaf_clk));
 CLKBUF_X1 clkload0 (.A(clknet_1_1__leaf_clk));
 DFFR_X1 \dut.fall_counter[0]$_DFFE_PP0P_  (.D(_015_),
    .RN(_011_),
    .CK(clknet_1_1__leaf_clk),
    .Q(\dut.fall_counter[0] ),
    .QN(_007_));
 DFFR_X1 \dut.fall_counter[1]$_DFFE_PP0P_  (.D(_014_),
    .RN(_011_),
    .CK(clknet_1_1__leaf_clk),
    .Q(\dut.fall_counter[1] ),
    .QN(_061_));
 DFFR_X1 \dut.fall_counter[2]$_DFFE_PP0P_  (.D(_013_),
    .RN(_011_),
    .CK(clknet_1_1__leaf_clk),
    .Q(\dut.fall_counter[2] ),
    .QN(_060_));
 DFFR_X1 \dut.fall_counter[3]$_DFFE_PP0P_  (.D(_016_),
    .RN(_011_),
    .CK(clknet_1_1__leaf_clk),
    .Q(\dut.fall_counter[3] ),
    .QN(_055_));
 DFFR_X1 \dut.fall_counter[4]$_DFFE_PP0P_  (.D(_012_),
    .RN(_011_),
    .CK(clknet_1_1__leaf_clk),
    .Q(\dut.fall_counter[4] ),
    .QN(_006_));
 DFFS_X1 \dut.state[0]$_DFF_PP1_  (.D(_002_),
    .SN(_011_),
    .CK(clknet_1_0__leaf_clk),
    .Q(net8),
    .QN(_058_));
 DFFR_X1 \dut.state[1]$_DFF_PP0_  (.D(_003_),
    .RN(_011_),
    .CK(clknet_1_0__leaf_clk),
    .Q(\dut.state[1] ),
    .QN(_054_));
 DFFR_X1 \dut.state[2]$_DFF_PP0_  (.D(_000_),
    .RN(_011_),
    .CK(clknet_1_0__leaf_clk),
    .Q(\dut.state[2] ),
    .QN(_056_));
 DFFR_X1 \dut.state[4]$_DFF_PP0_  (.D(_004_),
    .RN(_011_),
    .CK(clknet_1_0__leaf_clk),
    .Q(net9),
    .QN(_059_));
 DFFR_X1 \dut.state[5]$_DFF_PP0_  (.D(_005_),
    .RN(_011_),
    .CK(clknet_1_0__leaf_clk),
    .Q(\dut.state[5] ),
    .QN(_053_));
 DFFR_X1 \dut.state[6]$_DFF_PP0_  (.D(_001_),
    .RN(_011_),
    .CK(clknet_1_0__leaf_clk),
    .Q(\dut.state[6] ),
    .QN(_057_));
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
