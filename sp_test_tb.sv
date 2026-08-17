`timescale 1 ps / 1 ps

module sp_test_tb();
    // Constants
    parameter SYS_CLOCK_PERIOD = 10000;        //100MHz

    logic          dataReady;
    logic [31:0]   error;
    logic [31:0]   integral;
    logic [31:0]   derivative;
    wire  [31:0]   output_1;
    wire           outputReady;
    logic [31:0]   kp;
    logic [31:0]   ki;
    logic [31:0]   kd;
    logic          reset;
    logic          clk;

    PIDtestElement uut(
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



    initial begin
        clk = 1;
        forever
            #(SYS_CLOCK_PERIOD/2) clk = !clk;
    end

    shortreal _kp, _kd, _ki, _error, _deriv, _integral, _expected;

    initial begin
        //
        _kp = 0.1;
        _ki = 0.2;
        _kd = 0.3;
        _error = 1.0;
        _deriv = 1.5;
        _integral = 2.0;
        _expected = 0.0;
        //
        #10
        dataReady <= 0;

        //
        reset <= 1'b0;
        #100_000
        reset <= 1'b1;
        #100_000
        reset <= 1'b0;
        repeat (20) @(posedge clk);
        //
        error <=  $shortrealtobits(_error);
        integral <= $shortrealtobits(_integral);
        derivative <= $shortrealtobits(_deriv);
        kp <= $shortrealtobits(_kp);
        ki <= $shortrealtobits(_ki);
        kd <= $shortrealtobits(_kd);

        _expected = _kp*_error + _ki*_integral + _kd*_deriv;
        repeat (20) @(posedge clk);
        dataReady <= 1'b1;
        @(posedge clk);
        dataReady <= 1'b0;
        
        repeat (100) @(posedge clk);
       _kp = 1.1;
        _ki = 2.2;
        _kd = 033;
        _error = -1.0;
        _deriv = -1.5;
        _integral = -2.0;
        _expected = 0.0;
                error <=  $shortrealtobits(_error);
        integral <= $shortrealtobits(_integral);
        derivative <= $shortrealtobits(_deriv);
        kp <= $shortrealtobits(_kp);
        ki <= $shortrealtobits(_ki);
        kd <= $shortrealtobits(_kd);
        _expected = _kp*_error + _ki*_integral + _kd*_deriv;
        
        repeat (20) @(posedge clk);
        dataReady <= 1'b1;
        @(posedge clk);
        dataReady <= 1'b0;
        
        repeat (100) @(posedge clk);

        $stop;
    end


    task automatic wait_and_print(
        input string channel_name = ""
    );
        @(posedge outputReady);
        #10 
        $display("[%t] %s: got %f [0x%x]\texpected %f [0x%x]\t delta: %f", $time, channel_name, $bitstoshortreal(output_1), output_1, _expected, $shortrealtobits(_expected), ($abs($bitstoshortreal(output_1) - _expected)) );
        if($abs($bitstoshortreal(output_1) - _expected) < 1e-5) $display("OK!");
        else $display("FAILED!");
            
    endtask

    initial begin
    forever begin
        wait_and_print("output flow");
    end
    end        

endmodule