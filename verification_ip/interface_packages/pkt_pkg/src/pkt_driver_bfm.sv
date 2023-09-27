//----------------------------------------------------------------------
// Created with uvmf_gen version 2022.3
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//     
// DESCRIPTION: 
//    This interface performs the pkt signal driving.  It is
//     accessed by the uvm pkt driver through a virtual interface
//     handle in the pkt configuration.  It drives the singals passed
//     in through the port connection named bus of type pkt_if.
//
//     Input signals from the pkt_if are assigned to an internal input
//     signal with a _i suffix.  The _i signal should be used for sampling.
//
//     The input signal connections are as follows:
//       bus.signal -> signal_i 
//
//     This bfm drives signals with a _o suffix.  These signals
//     are driven onto signals within pkt_if based on INITIATOR/RESPONDER and/or
//     ARBITRATION/GRANT status.  
//
//     The output signal connections are as follows:
//        signal_o -> bus.signal
//
//                                                                                           
//      Interface functions and tasks used by UVM components:
//
//             configure:
//                   This function gets configuration attributes from the
//                   UVM driver to set any required BFM configuration
//                   variables such as 'initiator_responder'.                                       
//                                                                                           
//             initiate_and_get_response:
//                   This task is used to perform signaling activity for initiating
//                   a protocol transfer.  The task initiates the transfer, using
//                   input data from the initiator struct.  Then the task captures
//                   response data, placing the data into the response struct.
//                   The response struct is returned to the driver class.
//
//             respond_and_wait_for_next_transfer:
//                   This task is used to complete a current transfer as a responder
//                   and then wait for the initiator to start the next transfer.
//                   The task uses data in the responder struct to drive protocol
//                   signals to complete the transfer.  The task then waits for 
//                   the next transfer.  Once the next transfer begins, data from
//                   the initiator is placed into the initiator struct and sent
//                   to the responder sequence for processing to determine 
//                   what data to respond with.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
import uvmf_base_pkg_hdl::*;
import pkt_pkg_hdl::*;
import pkt_pkg::*;

interface pkt_driver_bfm #(
  int DATA_WIDTH = 240,
  int STATUS_WIDTH = 230
  )

  (pkt_if bus);

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
      $psprintf("The BFM at '%m' has the following parameters: DATA_WIDTH=%x STATUS_WIDTH=%x ", DATA_WIDTH,STATUS_WIDTH),
      UVM_DEBUG)
end
`endif

  // Config value to determine if this is an initiator or a responder 
  uvmf_initiator_responder_t initiator_responder;
  // Custom configuration variables.  
  // These are set using the configure function which is called during the UVM connect_phase
  bit [DATA_WIDTH-1:0] src_address ;

  tri pclk_i;
  tri prst_i;

  // Signal list (all signals are capable of being inputs and outputs for the sake
  // of supporting both INITIATOR and RESPONDER mode operation. Expectation is that 
  // directionality in the config file was from the point-of-view of the INITIATOR

  // INITIATOR mode input signals
  tri  rdy_i;
  reg  rdy_o = 1'b1;
  tri [STATUS_WIDTH-1:0] status_i;
  reg [STATUS_WIDTH-1:0] status_o = 'bz;

  // INITIATOR mode output signals
  tri  sop_i;
  reg  sop_o = 1'b0;
  tri  eop_i;
  reg  eop_o = 1'b0;
  tri [DATA_WIDTH-1:0] data_i;
  reg [DATA_WIDTH-1:0] data_o = 'bz;

  // Bi-directional signals
  

  assign pclk_i = bus.pclk;
  assign prst_i = bus.prst;

  // These are signals marked as 'input' by the config file, but the signals will be
  // driven by this BFM if put into RESPONDER mode (flipping all signal directions around)
  assign rdy_i = bus.rdy;
  assign bus.rdy = (initiator_responder == RESPONDER) ? rdy_o : 'bz;
  assign status_i = bus.status;
  assign bus.status = (initiator_responder == RESPONDER) ? status_o : 'bz;


  // These are signals marked as 'output' by the config file, but the outputs will
  // not be driven by this BFM unless placed in INITIATOR mode.
  assign bus.sop = (initiator_responder == INITIATOR) ? sop_o : 'bz;
  assign sop_i = bus.sop;
  assign bus.eop = (initiator_responder == INITIATOR) ? eop_o : 'bz;
  assign eop_i = bus.eop;
  assign bus.data = (initiator_responder == INITIATOR) ? data_o : 'bz;
  assign data_i = bus.data;

  // Proxy handle to UVM driver
  pkt_pkg::pkt_driver #(
    .DATA_WIDTH(DATA_WIDTH),
    .STATUS_WIDTH(STATUS_WIDTH)
    )
  proxy;


  // ****************************************************************************
// pragma uvmf custom reset_condition_and_response begin
  // Always block used to return signals to reset value upon assertion of reset
  always @( posedge prst_i )
     begin
       // RESPONDER mode output signals
       rdy_o <= 1'b1;
       status_o <= 'bz;
       // INITIATOR mode output signals
       sop_o <= 1'b0;
       eop_o <= 1'b0;
       data_o <= 'bz;
       // Bi-directional signals
 
     end    
// pragma uvmf custom reset_condition_and_response end

  // pragma uvmf custom interface_item_additional begin
  // pragma uvmf custom interface_item_additional end

  //******************************************************************
  // The configure() function is used to pass agent configuration
  // variables to the driver BFM.  It is called by the driver within
  // the agent at the beginning of the simulation.  It may be called 
  // during the simulation if agent configuration variables are updated
  // and the driver BFM needs to be aware of the new configuration 
  // variables.
  //

  function void configure(pkt_configuration 
                         #(
                         DATA_WIDTH,
                         STATUS_WIDTH
                         )

                         pkt_configuration_arg
                         );  
    initiator_responder = pkt_configuration_arg.initiator_responder;
    src_address = pkt_configuration_arg.src_address;
  // pragma uvmf custom configure begin
  // pragma uvmf custom configure end
  endfunction                                                                             

// pragma uvmf custom initiate_and_get_response begin
// ****************************************************************************
// UVMF_CHANGE_ME
// This task is used by an initator.  The task first initiates a transfer then
// waits for the responder to complete the transfer.
    task initiate_and_get_response( pkt_transaction 
                                  #(
                                  DATA_WIDTH,
                                  STATUS_WIDTH
                                  )

                                  initiator_trans  
                                  );
       // 
       // Variables within the initiator_trans:
       //   bit [DATA_WIDTH-1:0] data ;
       //   bit [DATA_WIDTH-1:0] dst_address ;
       //   bit [STATUS_WIDTH-1:0] status ;
       //
       // Reference code;
       //    How to wait for signal value
       //      while (control_signal == 1'b1) @(posedge pclk_i);
       //    
       //    How to assign a initiator_trans variable, named xyz, from a signal.   
       //    All available initiator input and inout signals listed.
       //    Initiator input signals:
       //      initiator_trans.xyz = rdy_i;  //     
       //      initiator_trans.xyz = status_i;  //    [STATUS_WIDTH-1:0] 
       //    Initiator inout signals:
       //    How to assign a signal, named xyz, from a initiator_trans varaiable.   
       //    All available initiator output and inout signals listed.
       //    Notice the _o.  Those are storage variables that allow for procedural assignment.
       //    Initiator output signals:
       //      sop_o <= initiator_trans.xyz;  //     
       //      eop_o <= initiator_trans.xyz;  //     
       //      data_o <= initiator_trans.xyz;  //    [DATA_WIDTH-1:0] 
       //    Initiator inout signals:
    // Initiate a transfer using the data received.
    @(posedge pclk_i);
    @(posedge pclk_i);
    // Wait for the responder to complete the transfer then place the responder data into 
    // initiator_trans.
    @(posedge pclk_i);
    @(posedge pclk_i);
  endtask        
// pragma uvmf custom initiate_and_get_response end

// pragma uvmf custom respond_and_wait_for_next_transfer begin
// ****************************************************************************
// The first_transfer variable is used to prevent completing a transfer in the 
// first call to this task.  For the first call to this task, there is not
// current transfer to complete.
bit first_transfer=1;

// UVMF_CHANGE_ME
// This task is used by a responder.  The task first completes the current 
// transfer in progress then waits for the initiator to start the next transfer.
  
  task respond_and_wait_for_next_transfer( pkt_transaction 
                                         #(
                                         DATA_WIDTH,
                                         STATUS_WIDTH
                                         )

                                         responder_trans  
                                         );     
  // Variables within the responder_trans:
  //   bit [DATA_WIDTH-1:0] data ;
  //   bit [DATA_WIDTH-1:0] dst_address ;
  //   bit [STATUS_WIDTH-1:0] status ;
       // Reference code;
       //    How to wait for signal value
       //      while (control_signal == 1'b1) @(posedge pclk_i);
       //    
       //    How to assign a responder_trans member, named xyz, from a signal.   
       //    All available responder input and inout signals listed.
       //    Responder input signals
       //      responder_trans.xyz = sop_i;  //     
       //      responder_trans.xyz = eop_i;  //     
       //      responder_trans.xyz = data_i;  //    [DATA_WIDTH-1:0] 
       //    Responder inout signals
       //    How to assign a signal from a responder_trans member named xyz.   
       //    All available responder output and inout signals listed.
       //    Notice the _o.  Those are storage variables that allow for procedural assignment.
       ///   Responder output signals
       //      rdy_o <= responder_trans.xyz;  //     
       //      status_o <= responder_trans.xyz;  //    [STATUS_WIDTH-1:0] 
       //    Responder inout signals
    

  @(posedge pclk_i);
  if (!first_transfer) begin
    // Perform transfer response here.   
    // Reply using data recieved in the responder_trans.
    @(posedge pclk_i);
    // Reply using data recieved in the transaction handle.
    @(posedge pclk_i);
  end
    // Wait for next transfer then gather info from intiator about the transfer.
    // Place the data into the responder_trans handle.
    @(posedge pclk_i);
    @(posedge pclk_i);
    first_transfer = 0;
  endtask
// pragma uvmf custom respond_and_wait_for_next_transfer end

 
endinterface

// pragma uvmf custom external begin
// pragma uvmf custom external end

