
module fa(
  input logic a,
  input logic b,
  input logic ci,
  output logic s,
  output logic co
);

  assign s = a ^ b ^ ci;
  assign co = (a & b) | (b & ci) | (a & ci);
endmodule

module fa4 (
  input logic [3:0] a,
  input logic [3:0] b, 
  input logic ci,
  output logic [3:0] s,
  output logic co
);
  logic c1, c2, c3;

  fa fa1 (.a(a[0]), .b(b[0]), .ci(ci), .s(s[0]), .co(c1));
  fa fa2 (.a(a[1]), .b(b[1]), .ci(c1), .s(s[1]), .co(c2));
  fa fa3 (.a(a[2]), .b(b[2]), .ci(c2), .s(s[2]), .co(c3));
  fa fa4 (.a(a[3]), .b(b[3]), .ci(c3), .s(s[3]), .co(co));

endmodule

module bcdadd1 (
  input logic [3:0] a,
  input logic [3:0] b,
  input logic ci,
  output logic [3:0] s,
  output logic co
);

  logic [3:0] z;
  logic z4;
  logic f;
  logic c2;
  
  fa4 add1 (.a(a), .b(b), .ci(ci), .s(z), .co(z4));
  assign f = z4 | (z[3] & z[2]) | (z[3] & z[1]);

  fa4 add2 (.a(z), .b(f ? 4'b0110 : 4'b0000), .ci(1'b0), .s(s), .co(c2));
  assign co = f;
  

endmodule


module bcdadd4(
  input logic [15:0] a,
  input logic [15:0] b,
  input logic ci,
  output logic [15:0] s,
  output logic co
);
  logic c1, c2, c3;
  bcdadd1 d0 (.a(a[3:0]), .b(b[3:0]), .ci(ci), .s(s[3:0]), .co(c1));
  bcdadd1 d1 (.a(a[7:4]), .b(b[7:4]), .ci(c1), .s(s[7:4]), .co(c2));
  bcdadd1 d2 (.a(a[11:8]), .b(b[11:8]), .ci(c2), .s(s[11:8]), .co(c3));
  bcdadd1 d3 (.a(a[15:12]), .b(b[15:12]), .ci(c3), .s(s[15:12]), .co(co));

endmodule

module bcd9comp1(
  input logic [3:0] in,
  output logic [3:0] out
);

  always_comb begin
    case (in)
      4'd0: out = 4'd9;
      4'd1: out = 4'd8;
      4'd2: out = 4'd7;
      4'd3: out = 4'd6;
      4'd4: out = 4'd5;
      4'd5: out = 4'd4;
      4'd6: out = 4'd3;
      4'd7: out = 4'd2;
      4'd8: out = 4'd1;
      4'd9: out = 4'd0;

      // invalid BCD inputs
      default: out = 4'd0;
    endcase
  end
endmodule

module bcdaddsub4(
  input logic [15:0] a,
  input logic [15:0] b,
  input logic op,
  output logic [15:0] s
);

  logic [15:0] b_adj;
  logic unused_co;
  logic [3:0] b9_0, b9_1, b9_2, b9_3;

  bcd9comp1 c0 (.in(b[3:0]),    .out(b9_0));
  bcd9comp1 c1 (.in(b[7:4]),    .out(b9_1));
  bcd9comp1 c2 (.in(b[11:8]),   .out(b9_2));
  bcd9comp1 c3 (.in(b[15:12]),  .out(b9_3));
  
  assign b_adj[3:0]    = op ? b9_0 : b[3:0];
  assign b_adj[7:4]    = op ? b9_1 : b[7:4];
  assign b_adj[11:8]   = op ? b9_2 : b[11:8];
  assign b_adj[15:12]  = op ? b9_3 : b[15:12];
  bcdadd4 addsub(.a(a), .b(b_adj), .ci(op), .s(s), .co(unused_co));

endmodule



