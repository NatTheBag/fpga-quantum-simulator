// matrix multiplier unit

`default_nettype none

module qc_core #(
    parameter MAX_Q = 10, // max qubits
    parameter PW = 9 // program address bits
) (
    input wire clk, rst,

    //memory
    input wire prog_we, // convention we = write enable
    input wire [PW-1:0] prog_addr,
    input wire [15:0] prog_wdata,
    input wire [PW:0] prog_len, // how many gates total (we have to repeat this many times)

    // gate matrix retrieval
    input wire mat_we, 
    input wire [9:0] mat_addr,
    input wire [15:0] mat_wdata,

    // fsm utils
    input wire start, clear, // clear sets state to 0
    input wire [3:0] nq, // how many qubits this run
    output wire busy, 
    output reg done,
    output reg [31:0] cycles

    // output
    input wire [MAX_Q-2:0] rd_addr,
    output wire [31:0] rd_q0,
    output wire [31:0] rd_q1 // bank output. i want to separate because then we can multiply the 0 and 1 components separately. change later if not    
);

endmodule
