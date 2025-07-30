interface alu_assertions (
  input logic clk,
  input logic rst,
  input logic ce,
  input logic mode,
  input logic [`CMD_WIDTH-1:0] cmd,
  input logic [1:0] inp_valid,
  input logic cin,
  input logic [`OP_WIDTH-1:0] opa,
  input logic [`OP_WIDTH-1:0] opb,
`ifdef MUL_OP
  input logic [(2*`OP_WIDTH)-1:0] res,
`else
  input logic [`OP_WIDTH:0] res,
`endif
  input logic cout,
  input logic oflow,
  input logic g,
  input logic l,
  input logic e,
  input logic err
);

  // Counter to track clock cycles and skip first 2 cycles
  logic [7:0] cycle_count = 0;
  logic simulation_started = 0;
  
  always @(posedge clk) begin
    if (rst) begin
      cycle_count <= 0;
      simulation_started <= 0;
    end else begin
      if (cycle_count < 8'd2) begin
        cycle_count <= cycle_count + 1;
      end else begin
        simulation_started <= 1;
      end
    end
  end

  function bit is_two_operand_cmd(logic mode_val, logic [`CMD_WIDTH-1:0] cmd_val);
    if (mode_val == 1'b1) begin 
      return (cmd_val == `ADD || cmd_val == `SUB || cmd_val == `ADD_CIN || 
              cmd_val == `SUB_CIN || cmd_val == `CMP || cmd_val == `INC_MUL || 
              cmd_val == `SHL_MUL);
    end else begin 
      return (cmd_val == `AND || cmd_val == `NAND || cmd_val == `OR || 
              cmd_val == `NOR || cmd_val == `XOR || cmd_val == `XNOR || 
              cmd_val == `ROL || cmd_val == `ROR);
    end
  endfunction

  function bit is_valid_arith_cmd(logic [`CMD_WIDTH-1:0] cmd_val);
    return (cmd_val == `ADD || cmd_val == `SUB || cmd_val == `ADD_CIN || 
            cmd_val == `SUB_CIN || cmd_val == `INC_A || cmd_val == `DEC_A || 
            cmd_val == `INC_B || cmd_val == `DEC_B || cmd_val == `CMP || 
            cmd_val == `INC_MUL || cmd_val == `SHL_MUL);
  endfunction

  function bit is_valid_logic_cmd(logic [`CMD_WIDTH-1:0] cmd_val);
    return (cmd_val == `AND || cmd_val == `NAND || cmd_val == `OR || 
            cmd_val == `NOR || cmd_val == `XOR || cmd_val == `XNOR || 
            cmd_val == `NOT_A || cmd_val == `NOT_B || cmd_val == `SHR1_A || 
            cmd_val == `SHL1_A || cmd_val == `SHR1_B || cmd_val == `SHL1_B || 
            cmd_val == `ROL || cmd_val == `ROR);
  endfunction

  //=============================================================================
  // A. VALID CHECKS

  // 1.1 Clock validity check
  property clk_valid_check;
    @(posedge clk) !$isunknown(clk);
  endproperty
  assert_clk_valid: assert property (clk_valid_check)
    else $error("[ASSERTION] Clock signal is unknown at time %0t", $time);

  // 1.2 Reset validity check
  property rst_valid_check;
    @(posedge clk) !$isunknown(rst);
  endproperty
  assert_rst_valid: assert property (rst_valid_check)
    else $error("[ASSERTION] Reset signal is unknown at time %0t", $time);

  // 1.3 Clock enable validity check
  property ce_valid_check;
    @(posedge clk) disable iff (rst || !simulation_started) !$isunknown(ce);
  endproperty
  assert_ce_valid: assert property (ce_valid_check)
    else $error("[ASSERTION] Clock enable signal is unknown at time %0t", $time);

  // 1.4 Mode validity check
  property mode_valid_check;
    @(posedge clk) disable iff (rst || !simulation_started) !$isunknown(mode);
  endproperty
  assert_mode_valid: assert property (mode_valid_check)
    else $error("[ASSERTION] Mode signal is unknown at time %0t", $time);

  // 1.5 Command validity check
  property cmd_valid_check;
    @(posedge clk) disable iff (rst || !simulation_started) !$isunknown(cmd);
  endproperty
  assert_cmd_valid: assert property (cmd_valid_check)
    else $error("[ASSERTION] Command signal is unknown at time %0t", $time);

  // 1.6 Input valid check
  property inp_valid_check;
    @(posedge clk) disable iff (rst || !simulation_started) !$isunknown(inp_valid);
  endproperty
  assert_inp_valid: assert property (inp_valid_check)
    else $error("[ASSERTION] Input valid signal is unknown at time %0t", $time);

  // 1.7 Carry input check
  property cin_valid_check;
    @(posedge clk) disable iff (rst || !simulation_started) !$isunknown(cin);
  endproperty
  assert_cin_valid: assert property (cin_valid_check)
    else $error("[ASSERTION] Carry input signal is unknown at time %0t", $time);

  // 1.8 Operand validity check
  property operands_valid_check;
    @(posedge clk) disable iff (rst || !simulation_started) (!$isunknown(opa) && !$isunknown(opb));
  endproperty
  assert_operands_valid: assert property (operands_valid_check)
    else $error("[ASSERTION] Operand signals are unknown at time %0t", $time);

  // =============================================================================
  // B. TIMING RELATIONSHIP CHECKS

  // 2.1 Clock enable timing - outputs should not change when CE=0
  property ce_gating_check;
    @(posedge clk) disable iff (rst) 
    (!ce |-> ##1 ($stable(res) && $stable(cout) && $stable(oflow) && $stable(g) && $stable(l) && $stable(e) && $stable(err)));
  endproperty
  assert_ce_gating: assert property (ce_gating_check)
    else $error("[ASSERTION] Outputs changed when CE=0 at time %0t", $time);

  // =============================================================================
  // C. RESET CHECKS

  // 3.1 Reset state check - all outputs should be cleared during reset
  property reset_state_check;
    @(posedge clk)  (rst |-> ##1 (res == 0 && cout == 0 && oflow == 0 && g == 0 && l == 0 && e == 0 && err == 0));
  endproperty
  assert_reset_state: assert property (reset_state_check)
    else $error("[ASSERTION] Outputs not cleared during reset at time %0t", $time);

  // =============================================================================
  // D. PROTOCOL CHECKS
  // =============================================================================

  // 4.1 Command-Mode correlation check
  property cmd_mode_correlation;
    @(posedge clk) disable iff (rst || !simulation_started) 
    ((mode == 1'b1) |-> is_valid_arith_cmd(cmd)) or 
    ((mode == 1'b0) |-> is_valid_logic_cmd(cmd));
  endproperty
  assert_cmd_mode_correlation: assert property (cmd_mode_correlation)
    else $error("[ASSERTION] Invalid command-mode combination: mode=%b cmd=%0d at time %0t", mode, cmd, $time);

  // 4.2 Input valid protocol for single operand operations
  property single_op_inp_valid_arith_a;
    @(posedge clk) disable iff (rst || !simulation_started) 
    (mode == 1'b1 && (cmd == `INC_A || cmd == `DEC_A)) |-> (inp_valid == 2'b01);
  endproperty
  assert_single_op_arith_a: assert property (single_op_inp_valid_arith_a)
    else $error("[ASSERTION] INC_A/DEC_A requires inp_valid=01, got %b at time %0t", inp_valid, $time);

  property single_op_inp_valid_arith_b;
    @(posedge clk) disable iff (rst || !simulation_started) 
    (mode == 1'b1 && (cmd == `INC_B || cmd == `DEC_B)) |-> (inp_valid == 2'b10);
  endproperty
  assert_single_op_arith_b: assert property (single_op_inp_valid_arith_b)
    else $error("[ASSERTION] INC_B/DEC_B requires inp_valid=10, got %b at time %0t", inp_valid, $time);

  property single_op_inp_valid_logic_a;
    @(posedge clk) disable iff (rst || !simulation_started)
    (mode == 1'b0 && (cmd == `NOT_A || cmd == `SHL1_A || cmd == `SHR1_A)) |-> (inp_valid == 2'b01);
  endproperty
  assert_single_op_logic_a: assert property (single_op_inp_valid_logic_a)
    else $error("[ASSERTION] Single operand A logic ops require inp_valid=01, got %b at time %0t", inp_valid, $time);

  property single_op_inp_valid_logic_b;
    @(posedge clk) disable iff (rst || !simulation_started)
    (mode == 1'b0 && (cmd == `NOT_B || cmd == `SHL1_B || cmd == `SHR1_B)) |-> (inp_valid == 2'b10);
  endproperty
  assert_single_op_logic_b: assert property (single_op_inp_valid_logic_b)
    else $error("[ASSERTION] Single operand B logic ops require inp_valid=10, got %b at time %0t", inp_valid, $time);

  // 4.3 Two operand operations require inp_valid = 2'b11 (with tolerance for retry mechanism)
  property two_op_inp_valid_eventually;
    @(posedge clk) disable iff (rst || !simulation_started)
    (ce && is_two_operand_cmd(mode, cmd)) |-> ##[0:16] (inp_valid == 2'b11);
  endproperty
  assert_two_op_inp_valid: assert property (two_op_inp_valid_eventually)
    else $error("[ASSERTION] Two-operand operation did not get inp_valid=11 within 16 cycles at time %0t", $time);

  // =============================================================================
  // E. FLAG VALIDATION CHECKS
  // =============================================================================
  // 5.1 Flag mutual exclusivity for comparison operations
  property comparison_flag_exclusivity;
    @(posedge clk) disable iff (rst) 
    (ce && mode == 1'b1 && cmd == `CMP) |-> ##2 ($countones({g, l, e}) == 1);
  endproperty
  assert_flag_exclusivity: assert property (comparison_flag_exclusivity)
    else $error("[ASSERTION] Multiple comparison flags active simultaneously at time %0t", $time);

  // =============================================================================
  // F. PARAMETERIZED CHECKS
  // =============================================================================

  // 6.1 Operand width check
  property operand_width_check;
    @(posedge clk) disable iff (rst || !simulation_started)
    (opa < (1 << `OP_WIDTH)) && (opb < (1 << `OP_WIDTH));
  endproperty
  assert_operand_width: assert property (operand_width_check)
    else $error("[ASSERTION] Operand exceeds OP_WIDTH=%0d at time %0t", `OP_WIDTH, $time);

  // 6.2 Command width check
  property command_width_check;
    @(posedge clk) disable iff (rst || !simulation_started)
    (cmd < (1 << `CMD_WIDTH));
  endproperty
  assert_command_width: assert property (command_width_check)
    else $error("[ASSERTION] Command exceeds CMD_WIDTH=%0d at time %0t", `CMD_WIDTH, $time);

endinterface
