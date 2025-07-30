class alu_monitor;
  alu_transaction mon_trans;  
  mailbox #(alu_transaction) mbx_ms;
  virtual alu_if.MON vif;
  event drv_trigger_event; // Event to receive trigger from driver

  // Output functional coverage
  covergroup mon_cg;
    RESULT: coverpoint mon_trans.res {
      bins zero = {0};
      `ifdef MUL_OP
      bins small_val = {[1:(1<<(`OP_WIDTH))-1]};
      bins medium_val = {[(1<<(`OP_WIDTH)):(1<<(2*`OP_WIDTH-1))-1]};
      bins large_val = {[(1<<(2*`OP_WIDTH-1)):(1<<(2*`OP_WIDTH))-1]};
      `else
      bins small_val = {[1:(1<<(`OP_WIDTH/2))-1]};
      bins medium_val = {[(1<<(`OP_WIDTH/2)):(1<<(`OP_WIDTH-1))-1]};
      bins large_val = {[(1<<(`OP_WIDTH-1)):(1<<`OP_WIDTH)-1]};
      `endif
    }
    
    COUT: coverpoint mon_trans.cout {
      bins no_carry = {1'b0};
      bins carry = {1'b1};
    }

    OFLOW: coverpoint mon_trans.oflow {
      bins no_overflow = {1'b0};
      bins overflow = {1'b1};
    }
    
    G_FLAG: coverpoint mon_trans.g {
      bins not_greater = {1'b0};
      bins greater = {1'b1};
    }

    L_FLAG: coverpoint mon_trans.l {
      bins not_less = {1'b0};
      bins less = {1'b1};
    }

    E_FLAG: coverpoint mon_trans.e {
      bins not_equal = {1'b0};
      bins equal = {1'b1};
    }
    
    ERR_FLAG: coverpoint mon_trans.err {
      bins no_error = {1'b0};
      bins error = {1'b1};
    }
    
  endgroup

  function new(mailbox #(alu_transaction) mbx_ms, virtual alu_if.MON vif, event drv_trigger_event);
    this.mbx_ms = mbx_ms;
    this.vif = vif;
    this.drv_trigger_event = drv_trigger_event;
    mon_cg = new();
  endfunction

  task start();
    integer i;
    
    $display("[%0t] MONITOR: Starting to monitor transactions", $time);
    
    for(i = 0; i < `no_of_trans; i++) begin
        mon_trans = new();
        
        @(drv_trigger_event);
        
        $display("[%0t] MONITOR: Received trigger from driver for transaction %0d", $time, i);

            mon_trans.res = vif.mon_cb.res;
            mon_trans.cout = vif.mon_cb.cout;
            mon_trans.oflow = vif.mon_cb.oflow;
            mon_trans.g = vif.mon_cb.g;
            mon_trans.l = vif.mon_cb.l;
            mon_trans.e = vif.mon_cb.e;
            mon_trans.err = vif.mon_cb.err;
            mbx_ms.put(mon_trans);
            mon_cg.sample();
            $display("[%0t] MONITOR: Transaction %0d - res=0x%0h cout=%0b oflow=%0b g=%0b l=%0b e=%0b err=%0b", $time, i, mon_trans.res, mon_trans.cout, mon_trans.oflow, mon_trans.g, mon_trans.l, mon_trans.e, mon_trans.err);
    end
    
    $display("[%0t] MONITOR: Output Coverage = %0.2f%%", $time, mon_cg.get_coverage());
  endtask
endclass
