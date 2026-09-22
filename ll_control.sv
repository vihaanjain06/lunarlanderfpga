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