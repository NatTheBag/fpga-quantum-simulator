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
    // some variables

    localparam S_IDLE = 4'd0, S_CLR = 4'd1, S_FETCH = 4'd2, S_DEC = 4'd3, S_RD = 4'd4,
               S_TA = 4'd5, S_TB = 4'd6, S_MUL = 4'd7, S_ACC = 4'd8, S_WR = 4'd9;
    reg [3:0] state;
    assign busy = (state != S_IDLE);
    wire idle = (state == S_IDLE);
    wire clr = (state == S_CLR);

    reg [PW:0] pc; // what gate
    reg [AW-1:0] j; // what pair
    reg [3:0] nq_r; // num of qubits, for storage to counteract async.           

    // matrix multipler here... do later...

    //cycle counter
    always @(posedge clk) begin
        if (rst | (idle & start))
            cycles <= 32'd0;
        else if (!idle && !clr)
            cycles <= cycles + 1'b1;
    end

    // fsm
    wire finish_term = (state == S_ACC) | ((state == S_TB) & (mq == 16'sd0))
    wire signed [33:0] acc;
    wire signed[33:0] prod_x = {{1{prod[32]}}, prod};
    wire signed[33:0] acc_mul = sub? acc - prod_x : acc+prod_x;
    wire signed acc_new = (state == S_ACC) ? acc_mul : acc;
    wire signed [15:0] out16 = acc_new[29:14];

    always @(posedge clk) begin
        done <= 1'b0;
        if (rst) begin
            state <= S_IDLE;
            pc <= {(PW+1){1'b0}};
            j <= {AW{1'b0}};
        end else begin
            if (finish_term) begin
                if (last_of_output) begin
                    case (t[3:2])
                        2'd0: r0 <= out16;
                        2'd1: r1 <= out16;
                        default: r3 <= out16;
                    endcase
                    acc <= RND;
                end else 
                    acc <= acc_new;
                t <= t + 1'b1;
                state <= (t == 4'd15) ? S_WR : S_TA;
            end

            case (state)
            S_IDLE: if (start) begin
                nq_r <= nq;
                j <= {AW{1'b0}};
                pc <= {(PW+1){1'b0}};
                
                r0 <= ONE; 
                r1 <= 16'sd0;
                r2 <= 16'sd0;
                r3 <= 16'sd0; // all 0
                state <= clear ? S_CLR : S_FETCH;
            end

            S_CLR: begin
                r0 <= 16'sd0;
                j <= j + 1'b1;
                if (last_pair) state <= S_FETCH;
            end

            S_FETCH: state <= S_DEC;
            S_DEC: begin 
                j <= {AW{1'b0}};
                if (pc == prog_len) begin
                    done <= 1'b0;
                    state <= S_IDLE;

                end else 
                state <= S_RD;
            end

            




endmodule
