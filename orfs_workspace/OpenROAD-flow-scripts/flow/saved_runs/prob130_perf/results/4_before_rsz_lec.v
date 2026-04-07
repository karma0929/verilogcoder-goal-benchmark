module prob130_perf_top (a,
    b,
    c,
    d,
    e,
    q);
 input [3:0] a;
 input [3:0] b;
 input [3:0] c;
 input [3:0] d;
 input [3:0] e;
 output [3:0] q;

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
 wire _15_;
 wire _16_;
 wire _17_;
 wire _18_;
 wire _19_;
 wire net1;
 wire net2;
 wire net3;
 wire net4;
 wire net5;
 wire net6;
 wire net7;
 wire net8;
 wire net9;
 wire net10;
 wire net11;
 wire net12;
 wire net13;
 wire net14;
 wire net15;
 wire net16;
 wire net17;
 wire net18;
 wire net19;
 wire net20;
 wire net21;
 wire net22;
 wire net23;
 wire net24;

 MUX2_X1 _21_ (.A(net5),
    .B(net17),
    .S(net9),
    .Z(_01_));
 INV_X1 _22_ (.A(_01_),
    .ZN(_02_));
 NOR3_X2 _23_ (.A1(net10),
    .A2(net12),
    .A3(net11),
    .ZN(_03_));
 INV_X1 _24_ (.A(net10),
    .ZN(_04_));
 NOR3_X2 _25_ (.A1(_04_),
    .A2(net12),
    .A3(net11),
    .ZN(_05_));
 MUX2_X1 _26_ (.A(net1),
    .B(net13),
    .S(net9),
    .Z(_06_));
 INV_X1 _27_ (.A(_06_),
    .ZN(_07_));
 AOI22_X2 _28_ (.A1(_02_),
    .A2(_03_),
    .B1(_05_),
    .B2(_07_),
    .ZN(net21));
 MUX2_X1 _29_ (.A(net2),
    .B(net14),
    .S(net9),
    .Z(_08_));
 INV_X1 _30_ (.A(_08_),
    .ZN(_09_));
 MUX2_X1 _31_ (.A(net6),
    .B(net18),
    .S(net9),
    .Z(_10_));
 INV_X1 _32_ (.A(_10_),
    .ZN(_11_));
 AOI22_X1 _33_ (.A1(_05_),
    .A2(_09_),
    .B1(_11_),
    .B2(_03_),
    .ZN(net22));
 MUX2_X1 _34_ (.A(net3),
    .B(net15),
    .S(net9),
    .Z(_12_));
 INV_X1 _35_ (.A(_12_),
    .ZN(_13_));
 MUX2_X1 _36_ (.A(net7),
    .B(net19),
    .S(net9),
    .Z(_14_));
 INV_X1 _37_ (.A(_14_),
    .ZN(_15_));
 AOI22_X1 _38_ (.A1(_05_),
    .A2(_13_),
    .B1(_15_),
    .B2(_03_),
    .ZN(net23));
 MUX2_X1 _39_ (.A(net4),
    .B(net16),
    .S(net9),
    .Z(_16_));
 INV_X1 _40_ (.A(_16_),
    .ZN(_17_));
 MUX2_X1 _41_ (.A(net8),
    .B(net20),
    .S(net9),
    .Z(_18_));
 INV_X1 _42_ (.A(_18_),
    .ZN(_19_));
 AOI22_X1 _43_ (.A1(_05_),
    .A2(_17_),
    .B1(_19_),
    .B2(_03_),
    .ZN(net24));
 BUF_X1 input1 (.A(a[0]),
    .Z(net1));
 BUF_X1 input10 (.A(c[1]),
    .Z(net10));
 BUF_X1 input11 (.A(c[2]),
    .Z(net11));
 BUF_X1 input12 (.A(c[3]),
    .Z(net12));
 BUF_X1 input13 (.A(d[0]),
    .Z(net13));
 BUF_X1 input14 (.A(d[1]),
    .Z(net14));
 BUF_X1 input15 (.A(d[2]),
    .Z(net15));
 BUF_X1 input16 (.A(d[3]),
    .Z(net16));
 BUF_X1 input17 (.A(e[0]),
    .Z(net17));
 BUF_X1 input18 (.A(e[1]),
    .Z(net18));
 BUF_X1 input19 (.A(e[2]),
    .Z(net19));
 BUF_X1 input2 (.A(a[1]),
    .Z(net2));
 BUF_X1 input20 (.A(e[3]),
    .Z(net20));
 BUF_X1 input3 (.A(a[2]),
    .Z(net3));
 BUF_X1 input4 (.A(a[3]),
    .Z(net4));
 BUF_X1 input5 (.A(b[0]),
    .Z(net5));
 BUF_X1 input6 (.A(b[1]),
    .Z(net6));
 BUF_X1 input7 (.A(b[2]),
    .Z(net7));
 BUF_X1 input8 (.A(b[3]),
    .Z(net8));
 BUF_X1 input9 (.A(c[0]),
    .Z(net9));
 BUF_X1 output21 (.A(net21),
    .Z(q[0]));
 BUF_X1 output22 (.A(net22),
    .Z(q[1]));
 BUF_X1 output23 (.A(net23),
    .Z(q[2]));
 BUF_X1 output24 (.A(net24),
    .Z(q[3]));
endmodule
