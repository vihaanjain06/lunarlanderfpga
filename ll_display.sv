module ll_display(
  input logic clk,
  input logic rst,
  input logic land,
  input logic crash,
  input logic [3:0] disp_ctrl,
  input logic [15:0] alt,
  input logic [15:0] vel,
  input logic [15:0] fuel,
  input logic [15:0] thrust,
  output logic [7:0] ss7, ss6, ss5,
  output logic [7:0] ss3, ss2, ss1, ss0,
  output logic red,
  output logic green
);
  logic [1:0] mode, mode_n;
  logic [15:0] disp_val;
  logic [15:0] mag_val;
  logic neg;

  logic [23:0] msg;

  logic [6:0] seg3_raw, seg2_raw, seg1_raw, seg0_raw;
  logic en3, en2, en1, en0;

  localparam [1:0] MODE_ALT  = 2'b00;
  localparam [1:0] MODE_VEL  = 2'b01;
  localparam [1:0] MODE_FUEL = 2'b10;
  localparam [1:0] MODE_THR  = 2'b11;

  localparam [23:0] MSG_ALT = 24'b11101110_01110000_11110000;
  localparam [23:0] MSG_VEL = 24'b01111100_11110010_01110000;
  localparam [23:0] MSG_GAS = 24'b11011110_11101110_11011010;
  localparam [23:0] MSG_THR = 24'b11110000_11101100_10100000;

  localparam [6:0] MINUS = 7'b1000000;

  bcdaddsub4 negate_bcd (
    .a(16'h0000),
    .b(disp_val),
    .op(1'b1),
    .s(mag_val)
  );

  ssdec dec3 (
    .in(neg ? mag_val[15:12] : disp_val[15:12]),
    .enable(en3),
    .out(seg3_raw)
  );

  ssdec dec2 (
    .in(neg ? mag_val[11:8] : disp_val[11:8]),
    .enable(en2),
    .out(seg2_raw)
  );

  ssdec dec1 (
    .in(neg ? mag_val[7:4] : disp_val[7:4]),
    .enable(en1),
    .out(seg1_raw)
  );

  ssdec dec0 (
    .in(neg ? mag_val[3:0] : disp_val[3:0]),
    .enable(en0),
    .out(seg0_raw)
  );

  assign red = crash;
  assign green = land;
  assign neg = (disp_val[15:12] == 4'd9);

  always_ff @(posedge clk or posedge rst) begin
    if (rst)
      mode <= MODE_ALT;
    else
      mode <= mode_n;
  end

  always_comb begin
    mode_n = mode;

    if (disp_ctrl[3])
      mode_n = MODE_ALT;
    else if (disp_ctrl[2])
      mode_n = MODE_VEL;
    else if (disp_ctrl[1])
      mode_n = MODE_FUEL;
    else if (disp_ctrl[0])
      mode_n = MODE_THR;
  end

  always_comb begin
    case (mode)
      MODE_ALT: begin
        disp_val = alt;
        msg = MSG_ALT;
      end
      MODE_VEL: begin
        disp_val = vel;
        msg = MSG_VEL;
      end
      MODE_FUEL: begin
        disp_val = fuel;
        msg = MSG_GAS;
      end
      default: begin
        disp_val = thrust;
        msg = MSG_THR;
      end
    endcase
  end

  always_comb begin
    if (neg) begin
      en3 = 1'b0;
      en2 = (mag_val[11:8] != 4'd0);
      en1 = (mag_val[11:8] != 4'd0) || (mag_val[7:4] != 4'd0);
      en0 = 1'b1;
    end
    else begin
      en3 = (disp_val[15:12] != 4'd0);
      en2 = (disp_val[15:12] != 4'd0) || (disp_val[11:8] != 4'd0);
      en1 = (disp_val[15:12] != 4'd0) || (disp_val[11:8] != 4'd0) || (disp_val[7:4] != 4'd0);
      en0 = 1'b1;
    end
  end

  always_comb begin
    ss7 = 8'b0;
    ss6 = 8'b0;
    ss5 = 8'b0;
    ss3 = 8'b0;
    ss2 = 8'b0;
    ss1 = 8'b0;
    ss0 = 8'b0;

    ss7[6:0] = msg[23:17];
    ss6[6:0] = msg[15:9];
    ss5[6:0] = msg[7:1];

    ss0[6:0] = seg0_raw;
    ss1[6:0] = seg1_raw;
    ss2[6:0] = seg2_raw;

    if (neg)
      ss3[6:0] = MINUS;
    else
      ss3[6:0] = seg3_raw;
  end
endmodule