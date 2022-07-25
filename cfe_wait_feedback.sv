module cfe_wait_feedback #(
  parameter CFE_NBW_FO    = 'd13,
  parameter CFE_NBI_FO    = -'sd2,
  parameter CFE_NBW_LAT   = 'd32
)
(
  // Clock
  input  logic clk,
  // Reset signal
  input  logic rst_async_n,
  // Valid Input data indication
  input  logic i_valid,
  // Freq Offset calculated by CFE
  input  logic [CFE_NBW_FO-1:0] i_fo_value,

  // Feedback wait time
  output logic [CFE_NBW_LAT-1:0] o_wait
);


// --------------------------------
// 1. Signals declaration
// --------------------------------
    
// Configuration - to be moved to register bank
  wire enable_feedback = 1;
  wire [CFE_NBW_FO-1:0] reset_threshold = 13'h200;
  wire [CFE_NBW_FO-1:0] increase_threshold = 13'h50;
  wire [CFE_NBW_LAT-1:0] increase_step = 32'h100;
  wire [CFE_NBW_LAT-1:0] default_wait = 32'h100;
  wire [CFE_NBW_LAT-1:0] max_wait = 32'h1000;

// Logic
  reg initialized = 0;
  reg [CFE_NBW_LAT-1:0] wait_w;
  var [CFE_NBW_LAT-1:0] wait_calc;
  reg [CFE_NBW_FO-1:0] last_fo;
  var [CFE_NBW_FO-1:0] diff;

  // 2 state FSM:
  // start: waiting for the first valid -> o_wait = default_wait
  // ready: at least one valid received, last_fo contains a valid value
  localparam
    start = 1'b0,
    ready = 1'b1;

  reg fsm_state, fsm_next_state; 

  always @(posedge clk) begin
    if (!rst_async_n) begin 
      wait_w = default_wait;
      wait_calc = default_wait;
      last_fo = 0;
      diff = 0;
      fsm_state = start;
    end
    else begin
      fsm_state = fsm_next_state;
    end
  end

  always @(posedge clk) begin
    case (fsm_state)
      start: begin
        if (i_valid) begin
          last_fo = i_fo_value;
          fsm_next_state = ready;
        end else begin
          fsm_next_state = start;
        end
      end

      ready: begin
        fsm_next_state = ready;

        // If CFE is outputing a valid value
        if (i_valid) begin
          // Compute absolute diff from last freq offset
          diff = i_fo_value - last_fo;
          if (diff[CFE_NBW_FO-1] == 1)
            diff = -diff;

          // Update last freq. offset value
          last_fo = i_fo_value;
          // If diff is too large, reset wait to default
          if (diff > reset_threshold)
            wait_w = default_wait;
          // If diff is small, increase wait respecting max wait
          else if (diff < increase_threshold) begin
            wait_calc = wait_w + increase_step;
            if (wait_calc > max_wait)
              wait_w = max_wait;
            else
              wait_w = wait_calc;
          end
          // Else, keep the last wait value
          else
            wait_w = wait_w;
        end
        else
          wait_w = wait_w;
      end
    endcase
  end

  // If this block is not enabled, use default wait  
  assign o_wait = enable_feedback ? wait_w : default_wait;
   
endmodule

