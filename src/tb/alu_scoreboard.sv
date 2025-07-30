class alu_scoreboard;
  alu_transaction expected_trans, actual_trans;
  mailbox #(alu_transaction) mbx_rs;
  mailbox #(alu_transaction) mbx_ms;
  
  int passed_transactions;
  int failed_transactions;

  function new(mailbox #(alu_transaction) mbx_rs, mailbox #(alu_transaction) mbx_ms);
    this.mbx_rs = mbx_rs;
    this.mbx_ms = mbx_ms;
    passed_transactions = 0;
    failed_transactions = 0;
  endfunction

  function bit compare_transactions(alu_transaction expected, alu_transaction actual);
    bit match = 1'b1;
    
    if (expected.res !== actual.res) begin
      $display("[%0t] SCOREBOARD: Result mismatch - Expected: 0x%h, Actual: 0x%h", $time, expected.res, actual.res);
      match = 1'b0;
    end
    
    if (expected.cout !== actual.cout) begin
      $display("[%0t] SCOREBOARD: Carry out mismatch - Expected: %0b, Actual: %0b", $time, expected.cout, actual.cout);
      match = 1'b0;
    end
    
    if (expected.oflow !== actual.oflow) begin
      $display("[%0t] SCOREBOARD: Overflow mismatch - Expected: %0b, Actual: %0b", $time, expected.oflow, actual.oflow);
      match = 1'b0;
    end
    
    if (expected.g !== actual.g) begin
      $display("[%0t] SCOREBOARD: Greater flag mismatch - Expected: %0b, Actual: %0b", $time, expected.g, actual.g);
      match = 1'b0;
    end 
    
    if (expected.l !== actual.l) begin
      $display("[%0t] SCOREBOARD: Less flag mismatch - Expected: %0b, Actual: %0b", $time, expected.l, actual.l);
      match = 1'b0;
    end

    if (expected.e !== actual.e) begin
      $display("[%0t] SCOREBOARD: Equal flag mismatch - Expected: %0b, Actual: %0b", $time, expected.e, actual.e);
      match = 1'b0;
    end    
    
    if (expected.err !== actual.err) begin
      $display("[%0t] SCOREBOARD: Error flag mismatch - Expected: %0b, Actual: %0b", $time, expected.err, actual.err);
      match = 1'b0;
    end
    
    return match;
  endfunction

  task start();
    
    for(int i = 0; i < `no_of_trans; i++) begin
      mbx_rs.get(expected_trans);
      mbx_ms.get(actual_trans);
      
      
      if (compare_transactions(expected_trans, actual_trans)) begin
        passed_transactions++;
        $display("[%0t] SCOREBOARD: Transaction %0d PASSED - mode=%0b cmd=0x%h opa=0x%h opb=0x%h", $time, i, expected_trans.mode, expected_trans.cmd, expected_trans.opa, expected_trans.opb);
      end else begin
        failed_transactions++;
        $display("[%0t] SCOREBOARD: Transaction %0d FAILED", $time, i);
        $display("  Input: mode=%0b cmd=0x%h inp_valid=%0b cin=%0b opa=0x%h opb=0x%h", expected_trans.mode, expected_trans.cmd, expected_trans.inp_valid, expected_trans.cin, expected_trans.opa, expected_trans.opb);
        $display("  Expected: res=0x%h cout=%0b oflow=%0b g=%0b l=%0b e=%0b err=%0b", expected_trans.res, expected_trans.cout, expected_trans.oflow, expected_trans.g, expected_trans.l, expected_trans.e, expected_trans.err);
        $display("  Actual:   res=0x%h cout=%0b oflow=%0b g=%0b l=%0b e=%0b err=%0b", actual_trans.res, actual_trans.cout, actual_trans.oflow, actual_trans.g, actual_trans.l, actual_trans.e, actual_trans.err);
      end
    end
    
    $display("[%0t] SCOREBOARD: FINAL REPORT", $time);
    $display("  Passed: %0d", passed_transactions);
    $display("  Failed: %0d", failed_transactions);
    
    if (failed_transactions == 0) begin
      $display("*** ALL TESTS PASSED! ***");
    end else begin
      $display("*** SOME TESTS FAILED! ***");
    end
  endtask
endclass
