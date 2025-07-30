class alu_generator;
  alu_transaction blueprint;
  mailbox #(alu_transaction) mbx_gd;
  
  function new(mailbox #(alu_transaction) mbx_gd);
    this.mbx_gd = mbx_gd;
    blueprint = new();
  endfunction

  task start();
    $display("[%0t] GENERATOR: Starting transaction generation", $time);   
    for(int i = 0; i < `no_of_trans; i++) begin
      if(!blueprint.randomize()) begin
            $display("[%0t] GENERATOR: Randomization failed for transaction %0d", $time, i);
      end
      mbx_gd.put(blueprint.clone());
      $display("[%0t] GENERATOR: Transaction %0d - ce=%0b mode=%0b cmd=%0d inp_valid=%b cin=%0b opa=0x%h opb=0x%h", $time, i, blueprint.ce, blueprint.mode, blueprint.cmd, blueprint.inp_valid, blueprint.cin, blueprint.opa, blueprint.opb);
    end
    
    $display("[%0t] GENERATOR: Completed generating %0d transactions", $time, `no_of_trans);
  endtask
endclass
