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