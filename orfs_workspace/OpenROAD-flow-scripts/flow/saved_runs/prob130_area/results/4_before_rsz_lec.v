module prob130_area_top (a,
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

 MUX2_X1 _15_ (.A(net7),
    .B(net19),
    .S(net9),
    .Z(_01_));
 MUX2_X1 _16_ (.A(net3),
    .B(net15),
    .S(net9),
    .Z(_02_));
 MUX2_X2 _18_ (.A(_01_),
    .B(_02_),
    .S(net10),
    .Z(_04_));
 OR3_X2 _19_ (.A1(net12),
    .A2(net11),
    .A3(_04_),
    .ZN(net23));
 MUX2_X1 _20_ (.A(net6),
    .B(net18),
    .S(net9),
    .Z(_05_));
 MUX2_X1 _21_ (.A(net2),
    .B(net14),
    .S(net9),
    .Z(_06_));
 MUX2_X2 _22_ (.A(_05_),
    .B(_06_),
    .S(net10),
    .Z(_07_));
 OR3_X2 _23_ (.A1(net12),
    .A2(net11),
    .A3(_07_),
    .ZN(net22));
 MUX2_X1 _24_ (.A(net5),
    .B(net17),
    .S(net9),
    .Z(_08_));
 MUX2_X1 _25_ (.A(net1),
    .B(net13),
    .S(net9),
    .Z(_09_));
 MUX2_X2 _26_ (.A(_08_),
    .B(_09_),
    .S(net10),
    .Z(_10_));
 OR3_X2 _27_ (.A1(net12),
    .A2(net11),
    .A3(_10_),
    .ZN(net21));
 MUX2_X1 _28_ (.A(net8),
    .B(net20),
    .S(net9),
    .Z(_11_));
 MUX2_X1 _29_ (.A(net4),
    .B(net16),
    .S(net9),
    .Z(_12_));
 MUX2_X2 _30_ (.A(_11_),
    .B(_12_),
    .S(net10),
    .Z(_13_));
 OR3_X2 _31_ (.A1(net12),
    .A2(net11),
    .A3(_13_),
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
