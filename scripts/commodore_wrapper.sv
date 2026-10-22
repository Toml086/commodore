module commodore_wrapper (
  input logic CLK_I,
  input logic RSTN_ASYNC_I,

  input logic [7:0] KEY_CODE,
  input logic KEY_VALID,
  output logic red,
  output logic green,
  output logic blue,
  output logic vsync,
  output logic hsync
);

logic clk_6m;
always_ff @(posedge CLK_I, negedge RSTN_ASYNC_I) begin
    if (~RSTN_ASYNC_I) begin
        clk_6m <= 1'b0;
    end else begin
        clk_6m <= ~clk_6m;
    end
end

commodore I_CORE (
  .CLK_I(clk_6m),
  .RST_ASYNC_I(~RSTN_ASYNC_I),      // Flip reset polarity
  .KEY_CODE(KEY_CODE),
  .KEY_VALID(KEY_VALID),
  .red(red),
  .green(green),
  .blue(blue),
  .vsync(vsync),
  .hsync(hsync),
);

endmodule
