class alu_environment;
  virtual alu_if drv_vif;
  virtual alu_if mon_vif;
  virtual alu_if ref_vif;
  
  alu_generator gen;
  alu_driver drv;
  alu_monitor mon;
  alu_reference_model ref_model;
  alu_scoreboard sb;
  event drv_trigger_event; // Event for driver to trigger monitor

  // Mailboxes for communication between components
  mailbox #(alu_transaction) mbx_gd; // Generator to Driver
  mailbox #(alu_transaction) mbx_dr; // Driver to Reference Model
  mailbox #(alu_transaction) mbx_ms; // Monitor to Scoreboard
  mailbox #(alu_transaction) mbx_rs; // Reference Model to Scoreboard

  function new(virtual alu_if drv_vif, virtual alu_if mon_vif, virtual alu_if ref_vif);
    this.drv_vif = drv_vif;
    this.mon_vif = mon_vif;
    this.ref_vif = ref_vif;
  endfunction

  task build();
    $display("[%0t] ENVIRONMENT: Building verification environment", $time);
    
    // Create mailboxes
    mbx_gd = new();
    mbx_dr = new();
    mbx_ms = new();
    mbx_rs = new();
    
    // Create verification components
    gen = new(mbx_gd);
    drv = new(mbx_gd, mbx_dr, drv_vif, drv_trigger_event);
    mon = new(mbx_ms, mon_vif, drv_trigger_event);
    ref_model = new(mbx_dr, mbx_rs, ref_vif);
    sb = new(mbx_rs, mbx_ms);
    
    $display("[%0t] ENVIRONMENT: Build completed", $time);
  endtask

  task start();
    $display("[%0t] ENVIRONMENT: Starting verification", $time);
    
    fork
      gen.start();
      drv.start();
      mon.start();
      ref_model.start();
      sb.start();
    join
    
    $display("[%0t] ENVIRONMENT: Verification completed", $time);
  endtask
endclass
