
module sp_test (
  input  wire          dataReady,
  input  wire [31:0]   error,
  input  wire [31:0]   integral,
  input  wire [31:0]   derivative,
  output wire [31:0]   output_1,
  output wire          outputReady,
  input  wire [31:0]   kp,
  input  wire [31:0]   ki,
  input  wire [31:0]   kd,
  input  wire          reset,
  input  wire          clk
);

    PIDtestElement inst(
    /*  input  wire        */  .dataReady   (dataReady),
    /*  input  wire [31:0] */  .error       (error),
    /*  input  wire [31:0] */  .integral    (integral),
    /*  input  wire [31:0] */  .derivative  (derivative),
    /*  output wire [31:0] */  .output_1    (output_1),
    /*  output wire        */  .outputReady (outputReady),
    /*  input  wire [31:0] */  .kp   (kp),
    /*  input  wire [31:0] */  .ki   (ki),
    /*  input  wire [31:0] */  .kd   (kd),
    /*  input  wire        */  .reset(reset),
    /*  input  wire        */  .clk  (clk)
    );

endmodule