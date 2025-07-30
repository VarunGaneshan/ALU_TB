class alu_test;
  virtual alu_if drv_vif;
  virtual alu_if mon_vif;
  virtual alu_if ref_vif;
  alu_environment env;

  function new(virtual alu_if drv_vif, virtual alu_if mon_vif, virtual alu_if ref_vif);
    this.drv_vif = drv_vif;
    this.mon_vif = mon_vif;
    this.ref_vif = ref_vif;
  endfunction

  task run();
    env = new(drv_vif, mon_vif, ref_vif);
    env.build();
    env.start();
  endtask
endclass

class alu_arith_test extends alu_test;
  alu_arith arithmetic_transaction;
  function new(virtual alu_if drv_vif, virtual alu_if mon_vif, virtual alu_if ref_vif);
    super.new(drv_vif, mon_vif, ref_vif); 
  endfunction

  task run();
    env = new(drv_vif, mon_vif, ref_vif);
    env.build();
    begin 
      arithmetic_transaction = new();
      env.gen.blueprint = arithmetic_transaction; // Upcasting
    end
    env.start();
    endtask
endclass

class alu_logical_test extends alu_test;
  alu_logical logical_transaction;
  function new(virtual alu_if drv_vif, virtual alu_if mon_vif, virtual alu_if ref_vif);
    super.new(drv_vif, mon_vif, ref_vif); 
  endfunction
  
  task run();
    env = new(drv_vif, mon_vif, ref_vif);
    env.build();
    begin 
      logical_transaction = new();
      env.gen.blueprint = logical_transaction; // Upcasting
    end
    env.start();
    endtask
endclass

class test_regression extends alu_test;
  alu_arith arith_transaction;
  alu_logical logical_transaction;

  function new(virtual alu_if drv_vif, virtual alu_if mon_vif, virtual alu_if ref_vif);
    super.new(drv_vif, mon_vif, ref_vif);
  endfunction

  task run();
    env = new(drv_vif, mon_vif, ref_vif);
    env.build();
    arith_transaction = new();
    env.gen.blueprint = arith_transaction; // Upcasting
    env.start();
    logical_transaction = new();
    env.gen.blueprint = logical_transaction; // Upcasting
    env.start();
    $display("[%0t] Regression test completed", $time);
  endtask
endclass