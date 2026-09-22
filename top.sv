`default_nettype none
// Empty top module

module top #(
  parameter FUEL=16'h800,
  parameter ALTITUDE = 16'h4500,
  parameter VELOCITY = 16'h0,
  parameter THRUST = 16'h5,
  parameter GRAVITY = 16'h5
)(
  // I/O ports
  input  logic hz100, reset,
  input  logic [20:0] pb,
  output logic [7:0] left, right,
         ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0,
  output logic red, green, blue,

  // UART ports
  output logic [7:0] txdata,
  input  logic [7:0] rxdata,
  output logic txclk, rxclk,
  input  logic txready, rxready
);

  // Your code goes here...\
  lunarlander ll (
        .hz100(hz100), .reset(reset), .in(pb[19:0]), 
        .red(red), .green(green),                       // for crashed/landed
        .ss0({ss0}), .ss1({ss1}), .ss2({ss2}), .ss3({ss3}),     // for values
        .ss5({ss5}), .ss6({ss6}), .ss7({ss7})                 // for display message
  );

  
  
  
endmodule

// Add more modules down here...

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


