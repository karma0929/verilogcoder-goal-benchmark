module prob240_area (clk,
    obs_valid,
    obs_tag,
    obs_y);
 input clk;
 output obs_valid;
 output [7:0] obs_tag;
 output [31:0] obs_y;

 wire _00_;
 wire _01_;
 wire _02_;
 wire _03_;
 wire _04_;
 wire _05_;
 wire _06_;
 wire _08_;
 wire _09_;
 wire _10_;
 wire _11_;
 wire _12_;
 wire _13_;
 wire _14_;
 wire _15_;
 wire _16_;
 wire _17_;
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
 wire _28_;
 wire _29_;
 wire _30_;
 wire _31_;
 wire net33;
 wire net34;
 wire net35;
 wire net36;
 wire net37;
 wire net38;
 wire net39;
 wire net40;
 wire \u_top.tag_count[0] ;
 wire \u_top.tag_count[1] ;
 wire \u_top.tag_count[2] ;
 wire \u_top.tag_count[3] ;
 wire \u_top.tag_count[4] ;
 wire \u_top.tag_count[5] ;
 wire \u_top.tag_count[6] ;
 wire \u_top.tag_count[7] ;
 wire clknet_1_1__leaf_clk;
 wire clknet_1_0__leaf_clk;
 wire clknet_0_clk;

 NAND3_X2 _35_ (.A1(\u_top.tag_count[1] ),
    .A2(\u_top.tag_count[2] ),
    .A3(\u_top.tag_count[0] ),
    .ZN(_08_));
 NAND4_X2 _36_ (.A1(\u_top.tag_count[4] ),
    .A2(\u_top.tag_count[5] ),
    .A3(\u_top.tag_count[3] ),
    .A4(\u_top.tag_count[6] ),
    .ZN(_09_));
 NOR2_X2 _37_ (.A1(_08_),
    .A2(_09_),
    .ZN(_10_));
 XOR2_X2 _38_ (.A(\u_top.tag_count[7] ),
    .B(_10_),
    .Z(_05_));
 AND2_X2 _39_ (.A1(\u_top.tag_count[4] ),
    .A2(\u_top.tag_count[3] ),
    .ZN(_11_));
 NAND4_X1 _40_ (.A1(\u_top.tag_count[2] ),
    .A2(\u_top.tag_count[5] ),
    .A3(_06_),
    .A4(_11_),
    .ZN(_12_));
 XNOR2_X1 _41_ (.A(\u_top.tag_count[6] ),
    .B(_12_),
    .ZN(_04_));
 NAND4_X1 _42_ (.A1(\u_top.tag_count[1] ),
    .A2(\u_top.tag_count[2] ),
    .A3(\u_top.tag_count[0] ),
    .A4(_11_),
    .ZN(_13_));
 XNOR2_X1 _43_ (.A(\u_top.tag_count[5] ),
    .B(_13_),
    .ZN(_03_));
 NAND3_X1 _44_ (.A1(\u_top.tag_count[2] ),
    .A2(\u_top.tag_count[3] ),
    .A3(_06_),
    .ZN(_14_));
 XNOR2_X1 _45_ (.A(\u_top.tag_count[4] ),
    .B(_14_),
    .ZN(_02_));
 XNOR2_X1 _46_ (.A(\u_top.tag_count[3] ),
    .B(_08_),
    .ZN(_01_));
 XOR2_X1 _47_ (.A(\u_top.tag_count[2] ),
    .B(_06_),
    .Z(_00_));
 HA_X1 _48_ (.A(\u_top.tag_count[0] ),
    .B(\u_top.tag_count[1] ),
    .CO(_06_),
    .S(_16_));
 LOGIC1_X1 _51__33 (.Z(obs_valid));
 LOGIC0_X1 _52__1 (.Z(obs_y[0]));
 LOGIC0_X1 _53__2 (.Z(obs_y[1]));
 LOGIC0_X1 _54__3 (.Z(obs_y[2]));
 LOGIC0_X1 _55__4 (.Z(obs_y[3]));
 LOGIC0_X1 _56__5 (.Z(obs_y[4]));
 LOGIC0_X1 _57__6 (.Z(obs_y[5]));
 LOGIC0_X1 _58__7 (.Z(obs_y[6]));
 LOGIC0_X1 _59__8 (.Z(obs_y[7]));
 LOGIC0_X1 _60__9 (.Z(obs_y[8]));
 LOGIC0_X1 _61__10 (.Z(obs_y[9]));
 LOGIC0_X1 _62__11 (.Z(obs_y[10]));
 LOGIC0_X1 _63__12 (.Z(obs_y[11]));
 LOGIC0_X1 _64__13 (.Z(obs_y[12]));
 LOGIC0_X1 _65__14 (.Z(obs_y[13]));
 LOGIC0_X1 _66__15 (.Z(obs_y[14]));
 LOGIC0_X1 _67__16 (.Z(obs_y[15]));
 LOGIC0_X1 _68__17 (.Z(obs_y[16]));
 LOGIC0_X1 _69__18 (.Z(obs_y[17]));
 LOGIC0_X1 _70__19 (.Z(obs_y[18]));
 LOGIC0_X1 _71__20 (.Z(obs_y[19]));
 LOGIC0_X1 _72__21 (.Z(obs_y[20]));
 LOGIC0_X1 _73__22 (.Z(obs_y[21]));
 LOGIC0_X1 _74__23 (.Z(obs_y[22]));
 LOGIC0_X1 _75__24 (.Z(obs_y[23]));
 LOGIC0_X1 _76__25 (.Z(obs_y[24]));
 LOGIC0_X1 _77__26 (.Z(obs_y[25]));
 LOGIC0_X1 _78__27 (.Z(obs_y[26]));
 LOGIC0_X1 _79__28 (.Z(obs_y[27]));
 LOGIC0_X1 _80__29 (.Z(obs_y[28]));
 LOGIC0_X1 _81__30 (.Z(obs_y[29]));
 LOGIC0_X1 _82__31 (.Z(obs_y[30]));
 LOGIC0_X1 _83__32 (.Z(obs_y[31]));
 CLKBUF_X3 clkbuf_0_clk (.A(clk),
    .Z(clknet_0_clk));
 CLKBUF_X3 clkbuf_1_0__f_clk (.A(clknet_0_clk),
    .Z(clknet_1_0__leaf_clk));
 CLKBUF_X3 clkbuf_1_1__f_clk (.A(clknet_0_clk),
    .Z(clknet_1_1__leaf_clk));
 BUF_X1 output34 (.A(net33),
    .Z(obs_tag[0]));
 BUF_X1 output35 (.A(net34),
    .Z(obs_tag[1]));
 BUF_X1 output36 (.A(net35),
    .Z(obs_tag[2]));
 BUF_X1 output37 (.A(net36),
    .Z(obs_tag[3]));
 BUF_X1 output38 (.A(net37),
    .Z(obs_tag[4]));
 BUF_X1 output39 (.A(net38),
    .Z(obs_tag[5]));
 BUF_X1 output40 (.A(net39),
    .Z(obs_tag[6]));
 BUF_X1 output41 (.A(net40),
    .Z(obs_tag[7]));
 DFF_X1 \u_top.out_tag[0]$_DFF_P_  (.D(\u_top.tag_count[0] ),
    .CK(clknet_1_0__leaf_clk),
    .Q(net33),
    .QN(_24_));
 DFF_X1 \u_top.out_tag[1]$_DFF_P_  (.D(\u_top.tag_count[1] ),
    .CK(clknet_1_0__leaf_clk),
    .Q(net34),
    .QN(_23_));
 DFF_X1 \u_top.out_tag[2]$_DFF_P_  (.D(\u_top.tag_count[2] ),
    .CK(clknet_1_1__leaf_clk),
    .Q(net35),
    .QN(_22_));
 DFF_X1 \u_top.out_tag[3]$_DFF_P_  (.D(\u_top.tag_count[3] ),
    .CK(clknet_1_0__leaf_clk),
    .Q(net36),
    .QN(_21_));
 DFF_X1 \u_top.out_tag[4]$_DFF_P_  (.D(\u_top.tag_count[4] ),
    .CK(clknet_1_1__leaf_clk),
    .Q(net37),
    .QN(_20_));
 DFF_X1 \u_top.out_tag[5]$_DFF_P_  (.D(\u_top.tag_count[5] ),
    .CK(clknet_1_1__leaf_clk),
    .Q(net38),
    .QN(_19_));
 DFF_X1 \u_top.out_tag[6]$_DFF_P_  (.D(\u_top.tag_count[6] ),
    .CK(clknet_1_1__leaf_clk),
    .Q(net39),
    .QN(_18_));
 DFF_X1 \u_top.out_tag[7]$_DFF_P_  (.D(\u_top.tag_count[7] ),
    .CK(clknet_1_0__leaf_clk),
    .Q(net40),
    .QN(_31_));
 DFF_X1 \u_top.tag_count[0]$_DFF_P_  (.D(_15_),
    .CK(clknet_1_0__leaf_clk),
    .Q(\u_top.tag_count[0] ),
    .QN(_15_));
 DFF_X1 \u_top.tag_count[1]$_DFF_P_  (.D(_16_),
    .CK(clknet_1_0__leaf_clk),
    .Q(\u_top.tag_count[1] ),
    .QN(_30_));
 DFF_X1 \u_top.tag_count[2]$_DFF_P_  (.D(_00_),
    .CK(clknet_1_1__leaf_clk),
    .Q(\u_top.tag_count[2] ),
    .QN(_29_));
 DFF_X1 \u_top.tag_count[3]$_DFF_P_  (.D(_01_),
    .CK(clknet_1_0__leaf_clk),
    .Q(\u_top.tag_count[3] ),
    .QN(_28_));
 DFF_X1 \u_top.tag_count[4]$_DFF_P_  (.D(_02_),
    .CK(clknet_1_1__leaf_clk),
    .Q(\u_top.tag_count[4] ),
    .QN(_27_));
 DFF_X1 \u_top.tag_count[5]$_DFF_P_  (.D(_03_),
    .CK(clknet_1_1__leaf_clk),
    .Q(\u_top.tag_count[5] ),
    .QN(_26_));
 DFF_X1 \u_top.tag_count[6]$_DFF_P_  (.D(_04_),
    .CK(clknet_1_1__leaf_clk),
    .Q(\u_top.tag_count[6] ),
    .QN(_25_));
 DFF_X1 \u_top.tag_count[7]$_DFF_P_  (.D(_05_),
    .CK(clknet_1_0__leaf_clk),
    .Q(\u_top.tag_count[7] ),
    .QN(_17_));
endmodule
