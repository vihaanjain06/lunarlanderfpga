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