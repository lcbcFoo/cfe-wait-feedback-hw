module testbench #(
  parameter CFE_NBW_FO    = 'd13,
  parameter CFE_NBI_FO    = -'sd2,
  parameter CFE_NBW_LAT   = 'd32
)
(
);

  // Clk 1GHz
  parameter int clk_period = 1000;
  parameter timeout = 1000000;    

  // Clock
  reg clk = 'b0;
  // Reset
  reg rst_async_n = 'b0;
  // Valid freq offset indicator
  reg i_valid = 'b0;
  // Freq offset value
  reg [CFE_NBW_FO-1:0] i_fo_value;
  // Feedback wait time
  reg [CFE_NBW_LAT-1:0] o_wait;

  cfe_wait_feedback cfe_wait_feedback
  (
    .clk(clk),                              // Clock - Fast clock
    .rst_async_n(rst_async_n),              // Reset signal (fast)
    .i_valid(i_valid),                      // Valid Input data indication
    .i_fo_value(i_fo_value),                // Output data
    .o_wait(o_wait)                         // Wait time selection
  );

  initial begin
    clk <= '0;
    forever #(clk_period / 2) clk = ~clk;
  end

  initial begin

    //--------------------------------------------------------------------
    // Wait time should be constant for 20 cycles
    // Then, increase twice
    // Then, maintain constant

    #(clk_period);
    rst_async_n = 1;
    i_fo_value = 13'h20;

    // i_valid = 0 => no changes to o_wait
    for (integer i = 1; i <= 20; i = i + 1) begin
      #(clk_period);
      assert (o_wait == 13'h100) $display ("o_wait is correct");
        else $error("o_wait has invalid value: %h, should be %h", o_wait,
          13'h100);
    end

    i_valid = 1;
    // First sampling after valid is set to one should not change o_wait
    #(clk_period);
    assert (o_wait == 13'h100) $display ("o_wait is correct");
      else $error("o_wait has invalid value: %h, should be %h", o_wait, 13'h100);

    #(clk_period);
    assert (o_wait == 13'h200) $display ("o_wait is correct");
      else $error("o_wait has invalid value: %h, should be %h", o_wait, 13'h200);

    i_fo_value = 13'h40;
    #(clk_period);
    assert (o_wait == 13'h300) $display ("o_wait is correct");
      else $error("o_wait has invalid value: %h, should be %h", o_wait, 13'h300);

    i_fo_value = 13'h100;
    #(clk_period);
    assert (o_wait == 13'h300) $display ("o_wait is correct");
      else $error("o_wait has invalid value: %h, should be %h", o_wait, 13'h300);

    i_fo_value = 13'h200;
    #(clk_period);
    assert (o_wait == 13'h300) $display ("o_wait is correct");
      else $error("o_wait has invalid value: %h, should be %h", o_wait, 13'h300);

    i_valid = 0;
    for (integer i = 1; i <= 30; i = i + 1) begin
      #(clk_period);
      assert (o_wait == 13'h300) $display ("o_wait is correct");
        else $error("o_wait has invalid value: %h, should be %h", o_wait,
          13'h300);
    end

    i_valid = 0;
    rst_async_n = 0;    
    #(clk_period);

    //--------------------------------------------------------------------
    // Wait time should increase till the max (h1000) than keep constant

    rst_async_n = 1;
    i_fo_value = 13'h80;
    i_valid = 1;

    for (integer i = 1; i <= 16; i = i + 1) begin
      #(clk_period);
      assert (o_wait == 13'h100 * i) $display ("o_wait is correct");
        else $error("o_wait has invalid value: %h, should be %h", o_wait,
          13'h100 * i);
    end
    for (integer i = 1; i <= 30; i = i + 1) begin
      #(clk_period);
      assert (o_wait == 13'h1000) $display ("o_wait is correct");
        else $error("o_wait has invalid value: %h, should be %h", o_wait,
          13'h1000);
    end

    i_valid = 0;
    rst_async_n = 0;    
    #(clk_period);

    //--------------------------------------------------------------------
    // Wait should increase 5 times, reset to default, increase to max 
    // (input of 0xffff = small negative) and do NOT reset to default
    // in the end when input changes to small positive

    rst_async_n = 1;
    i_fo_value = 13'h80;
    i_valid = 1;

    for (integer i = 1; i <= 5; i = i + 1) begin
      #(clk_period);
      assert (o_wait == 13'h100 * i) $display ("o_wait is correct");
        else $error("o_wait has invalid value: %h, should be %h", o_wait,
          13'h100 * i);
    end

    i_fo_value = 13'h500;
    #(clk_period);
    assert (o_wait == 13'h100) $display ("o_wait is correct");
      else $error("o_wait has invalid value: %h, should be %h", o_wait, 13'h100);

    i_fo_value = 13'hfff0;
    for (integer i = 1; i <= 16; i = i + 1) begin
      #(clk_period);
      assert (o_wait == 13'h100 * i) $display ("o_wait is correct");
        else $error("o_wait has invalid value: %h, should be %h", o_wait,
          13'h100 * i);
    end

    i_fo_value = 13'h20;
    #(clk_period);
    assert (o_wait == 13'h1000) $display ("o_wait is correct");
      else $error("o_wait has invalid value: %h, should be %h", o_wait, 13'h1000);


    i_valid = 0;
    rst_async_n = 0;    
    #(clk_period);

    //--------------------------------------------------------------------
    // Wait should increase to max (input is minimum negative) and
    // reset to default when change to positive with diff higher than
    // threshold

    rst_async_n = 1;
    i_fo_value = 13'hffff;
    i_valid = 1;

    for (integer i = 1; i <= 16; i = i + 1) begin
      #(clk_period);
      assert (o_wait == 13'h100 * i) $display ("o_wait is correct");
        else $error("o_wait has invalid value: %h, should be %h", o_wait,
          13'h100 * i);
    end

    i_fo_value = 13'h50;
    #(clk_period);
    assert (o_wait == 13'h1000) $display ("o_wait is correct");
      else $error("o_wait has invalid value: %h, should be %h", o_wait, 13'h1000);

    i_valid = 0;
    rst_async_n = 0;    
    #(clk_period);

    //--------------------------------------------------------------------

    $finish;
  end

endmodule
