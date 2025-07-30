class alu_driver;
  alu_transaction drv_trans;
  mailbox #(alu_transaction) mbx_gd;
  mailbox #(alu_transaction) mbx_dr;
  virtual alu_if.DRV vif;
  event drv_trigger_event; // Event to trigger monitor when output is ready

  // Input functional coverage
  covergroup drv_cg;
    OPERAND_A: coverpoint drv_trans.opa {
      bins zero = {0};
      bins small_val = {[1:(1<<(`OP_WIDTH/2))-1]};
      bins medium_val = {[(1<<(`OP_WIDTH/2)):(1<<(`OP_WIDTH-1))-1]};
      bins large_val = {[(1<<(`OP_WIDTH-1)):(1<<`OP_WIDTH)-2]};
      bins max = {(1<<`OP_WIDTH)-1};
    }
    
    OPERAND_B: coverpoint drv_trans.opb {
      bins zero = {0};
      bins small_val = {[1:(1<<(`OP_WIDTH/2))-1]};
      bins medium_val = {[(1<<(`OP_WIDTH/2)):(1<<(`OP_WIDTH-1))-1]};
      bins large_val = {[(1<<(`OP_WIDTH-1)):(1<<`OP_WIDTH)-2]};
      bins max = {(1<<`OP_WIDTH)-1};
    }
    
    MODE: coverpoint drv_trans.mode {
      bins arithmetic = {1'b1};
      bins logical = {1'b0};
    }
    
    CMD_ARITH: coverpoint drv_trans.cmd iff (drv_trans.mode == 1) {
      bins add = {`ADD};
      bins sub = {`SUB};
      bins add_cin = {`ADD_CIN};
      bins sub_cin = {`SUB_CIN};
      bins inc_a = {`INC_A};
      bins dec_a = {`DEC_A};
      bins inc_b = {`INC_B};
      bins dec_b = {`DEC_B};
      bins cmp = {`CMP};
      bins inc_mul = {`INC_MUL};
      bins shl_mul = {`SHL_MUL};
    }

    CMD_LOGIC: coverpoint drv_trans.cmd iff (drv_trans.mode == 0) {
      bins and_op = {`AND};
      bins nand_op = {`NAND};
      bins or_op = {`OR};
      bins nor_op = {`NOR};
      bins xor_op = {`XOR};
      bins xnor_op = {`XNOR};
      bins not_a = {`NOT_A};
      bins not_b = {`NOT_B};
      bins shr1_a = {`SHR1_A};
      bins shl1_a = {`SHL1_A};
      bins shr1_b = {`SHR1_B};
      bins shl1_b = {`SHL1_B};
      bins rol = {`ROL};
      bins ror = {`ROR};
    }
    
    INP_VALID: coverpoint drv_trans.inp_valid {
      //bins none = {2'b00};
      bins a_only = {2'b01};
      bins b_only = {2'b10};
      bins both = {2'b11};
    }
    
    CIN: coverpoint drv_trans.cin {
      bins no_carry = {1'b0};
      bins carry = {1'b1};
    }
    
    CE: coverpoint drv_trans.ce {
      bins disabled = {1'b0};
      bins enabled = {1'b1};
    }

  endgroup

  function new(mailbox #(alu_transaction) mbx_gd, mailbox #(alu_transaction) mbx_dr, virtual alu_if.DRV vif, event drv_trigger_event);
    this.mbx_gd = mbx_gd;
    this.mbx_dr = mbx_dr;
    this.vif = vif;
    this.drv_trigger_event = drv_trigger_event;
    drv_cg = new();
  endfunction

  // Function to get delay cycles based on command and mode
  function int get_delay_cycles;
    input [`CMD_WIDTH-1:0] cmd;
    input mode;
    begin
      if (mode && (cmd == `INC_MUL || cmd == `SHL_MUL))
        get_delay_cycles = 4;
      else
        get_delay_cycles = 3;
    end
  endfunction

  // Function to check if command is two operand
  function bit is_two_op;
    input [`CMD_WIDTH-1:0] c;
    input m;
    begin
      if (m == 1)
        is_two_op = (c == `ADD || c == `SUB || c == `ADD_CIN || c == `SUB_CIN || c == `CMP || c == `INC_MUL || c == `SHL_MUL);
      else
        is_two_op = (c == `AND || c == `NAND || c == `OR || c == `NOR || c == `XOR || c == `XNOR || c == `ROL || c == `ROR);
    end
  endfunction

  // Task to drive DUT and send to reference model
  task drive_dut_and_ref_model();
    vif.drv_cb.ce <= drv_trans.ce;
    vif.drv_cb.inp_valid <= drv_trans.inp_valid;
    vif.drv_cb.mode <= drv_trans.mode;
    vif.drv_cb.cmd <= drv_trans.cmd;
    vif.drv_cb.cin <= drv_trans.cin;
    vif.drv_cb.opa <= drv_trans.opa;
    vif.drv_cb.opb <= drv_trans.opb;
    mbx_dr.put(drv_trans);
  endtask

  task drive_dut();
    vif.drv_cb.ce <= drv_trans.ce;
    vif.drv_cb.inp_valid <= drv_trans.inp_valid;
    vif.drv_cb.mode <= drv_trans.mode;
    vif.drv_cb.cmd <= drv_trans.cmd;
    vif.drv_cb.cin <= drv_trans.cin;
    vif.drv_cb.opa <= drv_trans.opa;
    vif.drv_cb.opb <= drv_trans.opb;
  endtask

  // Task to trigger monitor after appropriate delay
  task trigger_monitor();
    int delay_cycles;
    delay_cycles = get_delay_cycles(drv_trans.cmd, drv_trans.mode);
    repeat(delay_cycles) @(vif.drv_cb);
    ->drv_trigger_event;
    $display("[%0t] DRIVER: Triggered monitor after %0d cycles", $time, delay_cycles);
  endtask

  task start();
    int retry_count;
    bit valid_match;
    
    for(int i = 0; i < `no_of_trans; i++) begin
        mbx_gd.get(drv_trans);    
        // Enable randomization for cmd and mode initially
        drv_trans.rand_mode(1);
        if(is_two_op(drv_trans.cmd, drv_trans.mode)) begin
            $display("[%0t] DRIVER: Transaction %0d - Two operand operation detected", $time, i);
            if(drv_trans.inp_valid == 2'b11) begin
                    $display("[%0t] DRIVER: Correct inp_valid found on transaction %0d", $time, i);
                    drive_dut_and_ref_model();
                    drv_cg.sample();
                    trigger_monitor();
            end else begin
                valid_match = 0;
                for(retry_count = 0; retry_count < 16; retry_count++) begin
                    if(drv_trans.inp_valid == 2'b11) begin
                        $display("[%0t] DRIVER: Correct inp_valid found on retry %0d", $time, retry_count);
                        drive_dut_and_ref_model();
                        drv_cg.sample();
                        trigger_monitor();
                        valid_match = 1;
                        break;
                    end else begin
                        $display("[%0t] DRIVER: Incorrect inp_valid=%b, driving DUT", $time, drv_trans.inp_valid);
                        drive_dut();
                        drv_cg.sample();                       
                        // Wait one cycle before next retry
                        repeat(1) @(vif.drv_cb);
                    end
                    // Disable randomization for cmd and mode after first iteration
                    drv_trans.cmd.rand_mode(0);
                    drv_trans.mode.rand_mode(0);  
                    // Re-randomize only inp_valid, opa, opb, cin, ce
                    if(!drv_trans.randomize()) begin
                        $display("[%0t] DRIVER: Randomization failed for retry %0d", $time, retry_count);
                    end
                  
                end
                // If all 16 retries failed, move to next transaction
                if(!valid_match) begin
                      $display("[%0t] DRIVER: All 16 retries failed for transaction %0d, moving to next", $time, i);
                      // Send to Reference model and trigger monitor for the last attempt to capture error
                      trigger_monitor();
                      mbx_dr.put(drv_trans);
                end
            end
            
        end else begin
            // Single operand operation - drive normally
            $display("[%0t] DRIVER: Transaction %0d - Single operand operation", $time, i);
            drive_dut_and_ref_model();
            drv_cg.sample();
            trigger_monitor();
        end
        
        $display("[%0t] DRIVER: Transaction %0d completed - ce=%0b mode=%0b cmd=%0d inp_valid=%b cin=%0b opa=0x%h opb=0x%h", 
                 $time, i, drv_trans.ce, drv_trans.mode, drv_trans.cmd, drv_trans.inp_valid, 
                 drv_trans.cin, drv_trans.opa, drv_trans.opb);
    end
    
    $display("[%0t] DRIVER: Input Coverage = %0.2f%%", $time, drv_cg.get_coverage());
  endtask
endclass