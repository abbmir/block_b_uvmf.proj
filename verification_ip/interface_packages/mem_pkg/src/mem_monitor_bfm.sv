//----------------------------------------------------------------------
// Created with uvmf_gen version 2022.3
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//     
// DESCRIPTION: This interface performs the mem signal monitoring.
//      It is accessed by the uvm mem monitor through a virtual
//      interface handle in the mem configuration.  It monitors the
//      signals passed in through the port connection named bus of
//      type mem_if.
//
//     Input signals from the mem_if are assigned to an internal input
//     signal with a _i suffix.  The _i signal should be used for sampling.
//
//     The input signal connections are as follows:
//       bus.signal -> signal_i 
//
//      Interface functions and tasks used by UVM components:
//             monitor(inout TRANS_T txn);
//                   This task receives the transaction, txn, from the
//                   UVM monitor and then populates variables in txn
//                   from values observed on bus activity.  This task
//                   blocks until an operation on the mem bus is complete.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
import uvmf_base_pkg_hdl::*;
import mem_pkg_hdl::*;
import mem_pkg::*;


interface mem_monitor_bfm #(
  int DATA_WIDTH = 220,
  int ADDR_WIDTH = 210
  )

  ( mem_if  bus );

`ifndef XRTL
// This code is to aid in debugging parameter mismatches between the BFM and its corresponding agent.
// Enable this debug by setting UVM_VERBOSITY to UVM_DEBUG
// Setting UVM_VERBOSITY to UVM_DEBUG causes all BFM's and all agents to display their parameter settings.
// All of the messages from this feature have a UVM messaging id value of "CFG"
// The transcript or run.log can be parsed to ensure BFM parameter settings match its corresponding agents parameter settings.
import uvm_pkg::*;
`include "uvm_macros.svh"
initial begin : bfm_vs_agent_parameter_debug
  `uvm_info("CFG", 
      $psprintf("The BFM at '%m' has the following parameters: DATA_WIDTH=%x ADDR_WIDTH=%x ", DATA_WIDTH,ADDR_WIDTH),
      UVM_DEBUG)
end
`endif


 mem_transaction #(
                      DATA_WIDTH,
                      ADDR_WIDTH
                      )
 
                      monitored_trans;
 

  // Config value to determine if this is an initiator or a responder 
  uvmf_initiator_responder_t initiator_responder;
  // Custom configuration variables.  
  // These are set using the configure function which is called during the UVM connect_phase
  bit [3:0] transfer_gap ;
  bit [3:0] speed_grade ;

  tri clock_i;
  tri reset_i;
  tri  cs_i;
  tri  rwn_i;
  tri  rdy_i;
  tri [ADDR_WIDTH-1:0] addr_i;
  tri [DATA_WIDTH-1:0] wdata_i;
  tri [DATA_WIDTH-1:0] rdata_i;
  assign clock_i = bus.clock;
  assign reset_i = bus.reset;
  assign cs_i = bus.cs;
  assign rwn_i = bus.rwn;
  assign rdy_i = bus.rdy;
  assign addr_i = bus.addr;
  assign wdata_i = bus.wdata;
  assign rdata_i = bus.rdata;

  // Proxy handle to UVM monitor
  mem_pkg::mem_monitor #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
    )
 proxy;

  // pragma uvmf custom interface_item_additional begin
  // pragma uvmf custom interface_item_additional end
  
  //******************************************************************                         
  task wait_for_reset(); 
    @(posedge clock_i) ;                                                                    
    do_wait_for_reset();                                                                   
  endtask                                                                                   

  // ****************************************************************************              
  task do_wait_for_reset(); 
  // pragma uvmf custom reset_condition begin
    wait ( reset_i === 0 ) ;                                                              
    @(posedge clock_i) ;                                                                    
  // pragma uvmf custom reset_condition end                                                                
  endtask    

  //******************************************************************                         
 
  task wait_for_num_clocks(input int unsigned count); 
    @(posedge clock_i);  
                                                                   
    repeat (count-1) @(posedge clock_i);                                                    
  endtask      

  //******************************************************************                         
  event go;                                                                                 
  function void start_monitoring();  
    -> go;
  endfunction                                                                               
  
  // ****************************************************************************              
  initial begin                                                                             
    @go;                                                                                   
    forever begin                                                                        
      @(posedge clock_i);  
      monitored_trans = new("monitored_trans");
      do_monitor( );
                                                                 
 
      proxy.notify_transaction( monitored_trans ); 
 
    end                                                                                    
  end                                                                                       

  //******************************************************************
  // The configure() function is used to pass agent configuration
  // variables to the monitor BFM.  It is called by the monitor within
  // the agent at the beginning of the simulation.  It may be called 
  // during the simulation if agent configuration variables are updated
  // and the monitor BFM needs to be aware of the new configuration 
  // variables.
  //
    function void configure(mem_configuration 
                         #(
                         DATA_WIDTH,
                         ADDR_WIDTH
                         )
 
                         mem_configuration_arg
                         );  
    initiator_responder = mem_configuration_arg.initiator_responder;
    transfer_gap = mem_configuration_arg.transfer_gap;
    speed_grade = mem_configuration_arg.speed_grade;
  // pragma uvmf custom configure begin
  // pragma uvmf custom configure end
  endfunction   


  // ****************************************************************************  
  task do_monitor();
    //
    // Available struct members:
    //     //    monitored_trans.read_data
    //     //    monitored_trans.write_data
    //     //    monitored_trans.address
    //     //    monitored_trans.byte_enable
    //     //    monitored_trans.chksum
    //     //
    // Reference code;
    //    How to wait for signal value
    //      while (control_signal === 1'b1) @(posedge clock_i);
    //    
    //    How to assign a transaction variable, named xyz, from a signal.   
    //    All available input signals listed.
    //      monitored_trans.xyz = cs_i;  //     
    //      monitored_trans.xyz = rwn_i;  //     
    //      monitored_trans.xyz = rdy_i;  //     
    //      monitored_trans.xyz = addr_i;  //    [ADDR_WIDTH-1:0] 
    //      monitored_trans.xyz = wdata_i;  //    [DATA_WIDTH-1:0] 
    //      monitored_trans.xyz = rdata_i;  //    [DATA_WIDTH-1:0] 
    // pragma uvmf custom do_monitor begin
    // UVMF_CHANGE_ME : Implement protocol monitoring.  The commented reference code 
    // below are examples of how to capture signal values and assign them to 
    // structure members.  All available input signals are listed.  The 'while' 
    // code example shows how to wait for a synchronous flow control signal.  This
    // task should return when a complete transfer has been observed.  Once this task is
    // exited with captured values, it is then called again to wait for and observe 
    // the next transfer. One clock cycle is consumed between calls to do_monitor.
    monitored_trans.start_time = $time;
    @(posedge clock_i);
    @(posedge clock_i);
    @(posedge clock_i);
    @(posedge clock_i);
    monitored_trans.end_time = $time;
    // pragma uvmf custom do_monitor end
  endtask         
  
 
endinterface

// pragma uvmf custom external begin
// pragma uvmf custom external end

