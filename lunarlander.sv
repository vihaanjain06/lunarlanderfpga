module lunarlander #(
  parameter FUEL=16'h800,
  parameter ALTITUDE=16'h4500,
  parameter VELOCITY=16'h0,
  parameter THRUST=16'h5,
  parameter GRAVITY=16'h5
)(
  input logic hz100, reset,
  input logic [19:0] in,
  output logic [7:0] ss7, ss6, ss5, 
  output logic [7:0] ss3, ss2, ss1, ss0,
  output logic red, green
);

  logic        clk;
  logic        keyclk;
  logic [4:0]  keyout;

  logic [15:0] alt;
  logic [15:0] vel;
  logic [15:0] fuel;
  logic [15:0] thrust;

  logic [15:0] alt_n;
  logic [15:0] vel_n;
  logic [15:0] fuel_n;
  logic [15:0] thrust_n;

  logic        land;
  logic        crash;
  logic        wen;

  logic [3:0]  disp_ctrl;

  // Slow game clock
  clock_psc u_clock_psc (
    .clk(hz100),
    .rst(reset),
    .lim(8'd24),
    .hzX(clk)
  );

  // Button synchronizer / encoder
  keysync u_keysync (
    .clk(hz100),
    .rst(reset),
    .keyin(in[19:0]),
    .keyout(keyout),
    .keyclk(keyclk)
  );

  // Thrust register:
  // update only for numeric keys 0-9, not W/X/Y/Z
  always_ff @(posedge keyclk or posedge reset) begin
    if (reset)
      thrust_n <= THRUST;
    else if (~keyout[4])
      thrust_n <= {12'b0, keyout[3:0]};
  end

  // Display mode control:
  // Z/Y/X/W -> ALT/VEL/FUEL/THRUST
  assign disp_ctrl = {
    (keyout == 5'd19), // Z
    (keyout == 5'd18), // Y
    (keyout == 5'd17), // X
    (keyout == 5'd16)  // W
  };

  // Memory block
  ll_memory #(
    .ALTITUDE(ALTITUDE),
    .VELOCITY(VELOCITY),
    .FUEL(FUEL),
    .THRUST(THRUST)
  ) u_ll_memory (
    .clk(clk),
    .rst(reset),
    .wen(wen),
    .alt_n(alt_n),
    .vel_n(vel_n),
    .fuel_n(fuel_n),
    .thrust_n(thrust_n),
    .alt(alt),
    .vel(vel),
    .fuel(fuel),
    .thrust(thrust)
  );

  // Arithmetic block
  ll_alu #(
    .GRAVITY(GRAVITY)
  ) u_ll_alu (
    .alt(alt),
    .vel(vel),
    .fuel(fuel),
    .thrust(thrust),
    .alt_n(alt_n),
    .vel_n(vel_n),
    .fuel_n(fuel_n)
  );

  // Control block
  ll_control u_ll_control (
    .clk(clk),
    .rst(reset),
    .alt(alt),
    .vel(vel),
    .land(land),
    .crash(crash),
    .wen(wen)
  );

  // Display block
  ll_display u_ll_display (
    .clk(keyclk),
    .rst(reset),
    .land(land),
    .crash(crash),
    .disp_ctrl(disp_ctrl),
    .alt(alt),
    .vel(vel),
    .fuel(fuel),
    .thrust(thrust),
    .ss7(ss7),
    .ss6(ss6),
    .ss5(ss5),
    .ss3(ss3),
    .ss2(ss2),
    .ss1(ss1),
    .ss0(ss0),
    .red(red),
    .green(green)
  );

endmodule

module keysync (
  input logic clk,
  input logic rst,
  input logic [19:0] keyin,
  output logic [4:0] keyout,
  output logic keyclk
);

  logic strobe_in;
  logic sync1, sync2;

  always_comb begin
    keyout[0] = keyin[1] | keyin[3] | keyin[5] | keyin[7] |
                keyin[9] | keyin[11] | keyin[13] | keyin[15] |
                keyin[17] | keyin[19];

    keyout[1] = keyin[2] | keyin[3] | keyin[6] | keyin[7] |
                keyin[10] | keyin[11] | keyin[14] | keyin[15] |
                keyin[18] | keyin[19];

    keyout[2] = keyin[4] | keyin[5] | keyin[6] | keyin[7] | keyin[12] | 
                keyin[13] | keyin[14] | keyin[15];

    keyout[3] = keyin[8] | keyin[9] | keyin[10] | keyin[11] |
                keyin[12] | keyin[13] | keyin[14] | keyin[15];

    keyout[4] = keyin[16] | keyin[17] | keyin[18] | keyin[19];

    strobe_in = |keyin;
  end

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      sync1 <= 1'b0;
      sync2 <= 1'b0;
      keyclk <= 1'b0;
    end
    else begin
      sync1 <= strobe_in;
      sync2 <= sync1;
      keyclk <= sync2;
    end
  end
endmodule
  
module clock_psc (
  input logic clk,
  input logic rst,
  input logic [7:0] lim,
  output logic hzX
);

  logic [7:0] count;
  logic hzX_div;

  assign hzX = (lim == 8'd0) ? clk : hzX_div;

  always_ff @(posedge clk or posedge rst) begin
      if (rst) begin
          count   <= 8'd0;
          hzX_div <= 1'b0;
      end
      else begin
          if (lim != 8'd0) begin
              if (count == lim) begin
                  count   <= 8'd0;
                  hzX_div <= ~hzX_div;
              end
              else begin
                  count <= count + 8'd1;
              end
          end
          else begin
              count   <= 8'd0;
              hzX_div <= 1'b0;
          end
      end
  end
endmodule

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

module ll_memory #(
  parameter ALTITUDE,
  parameter VELOCITY,
  parameter FUEL,
  parameter THRUST
)(
  input logic clk,
  input logic rst,
  input logic wen,
  input logic [15:0] alt_n,
  input logic [15:0] vel_n,
  input logic [15:0] fuel_n,
  input logic [15:0] thrust_n,
  output logic [15:0] alt,
  output logic [15:0] vel,
  output logic [15:0] fuel,
  output logic [15:0] thrust
);
  
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      alt <= ALTITUDE;
      vel <= VELOCITY;
      fuel <= FUEL;
      thrust <= THRUST;
    end
    else if (wen) begin
      alt <= alt_n;
      vel <= vel_n;
      fuel <= fuel_n;
      thrust <= thrust_n;
    end
  end

endmodule

module ll_alu #(
  parameter GRAVITY

)(
  input logic [15:0] alt,
  input logic [15:0] vel,
  input logic [15:0] fuel,
  input logic [15:0] thrust,
  output logic [15:0] alt_n,
  output logic [15:0] vel_n,
  output logic [15:0] fuel_n
);

  logic [15:0] alt_c;
  logic [15:0] vel_g;
  logic [15:0] vel_c;
  logic [15:0] fuel_c;
  logic [15:0] thrust_c;
  
  assign thrust_c = (fuel == 16'h0000) ? 16'h0000 : thrust;
  
  bcdaddsub4 add_alt (.a(alt), .b(vel), .op(0), .s(alt_c));
  bcdaddsub4 subtractgrav (.a(vel), .b(GRAVITY), .op(1), .s(vel_g));
  bcdaddsub4 add_thrust (.a(vel_g), .b(thrust_c), .op(0), .s(vel_c));
  bcdaddsub4 subtractfuel(.a(fuel), .b(thrust_c), .op(1), .s(fuel_c));
  
  always_comb begin
    alt_n = alt_c;
    vel_n = vel_c;
    fuel_n = fuel_c;
    
    if ((alt_c == 16'h0000) || (alt_c[15:12] == 4'd9)) begin
      alt_n = 16'h0;
      vel_n = 16'h0;
    end
    
    if ((fuel_c == 16'h0000) || (fuel_c[15:12] == 4'd9)) begin
      fuel_n = 16'h0;
    end
  end

endmodule

module ll_control (
  input logic clk,
  input logic rst,
  input logic [15:0] alt,
  input logic [15:0] vel,
  output logic land,
  output logic crash,
  output logic wen
);
  logic [15:0] alt_vel;
  
  logic land_n;
  logic crash_n;
  logic wen_n;
  
  bcdaddsub4 addaltvel(.a(alt), .b(vel), .op(0), .s(alt_vel));
  
  
  always_comb begin
    land_n  = land;
    crash_n = crash;
    wen_n   = wen;

    if (land || crash) begin
      land_n  = land;
      crash_n = crash;
      wen_n   = 0;
    end
    else begin
      if ((alt_vel == 16'h0000) || (alt_vel[15:12] == 4'd9)) begin
        if (vel < 16'h9970) begin
          crash_n = 1;
          land_n  = 0;
          wen_n   = 0;
        end
        else begin
          land_n  = 1;
          crash_n = 0;
          wen_n   = 0;
        end
      end
      else begin
        land_n  = 0;
        crash_n = 0;
        wen_n   = 1;
      end
    end
  end

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      land  <= 0;
      crash <= 0;
      wen   <= 0;
    end
    else begin
      land  <= land_n;
      crash <= crash_n;
      wen   <= wen_n;
    end
  end
  

endmodule

module ssdec (
    input logic [3:0] in,     
    input logic enable,       
    output logic [6:0] out    
);

    
    assign out = (enable) ? (
        (in == 4'b0000) ? 7'b0111111 : 
        (in == 4'b0001) ? 7'b0000110 : 
        (in == 4'b0010) ? 7'b1011011 : 
        (in == 4'b0011) ? 7'b1001111 : 
        (in == 4'b0100) ? 7'b1100110 : 
        (in == 4'b0101) ? 7'b1101101 : 
        (in == 4'b0110) ? 7'b1111101 : 
        (in == 4'b0111) ? 7'b0000111 : 
        (in == 4'b1000) ? 7'b1111111 : 
        (in == 4'b1001) ? 7'b1100111 : 
        (in == 4'b1010) ? 7'b1110111 :
        (in == 4'b1011) ? 7'b1111100 : 
        (in == 4'b1100) ? 7'b0111001 :
        (in == 4'b1101) ? 7'b1011110 : 
        (in == 4'b1110) ? 7'b1111001 : 
        (in == 4'b1111) ? 7'b1110001 : 
        7'b0000000  
    ) : 7'b0000000;  

endmodule

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