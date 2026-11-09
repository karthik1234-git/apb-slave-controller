module apb (
    input  wire        pclk,
    input  wire        presetn,
    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [3:0]  paddr,     // 16 memory locations
    input  wire [31:0] pwdata,
    output reg  [31:0] prdata,
    output wire        pready,
    output wire        pslverr
);

    localparam IDLE   = 2'b00;
    localparam SETUP  = 2'b01;
    localparam ACCESS = 2'b10;

    reg [1:0] state, next_state;
    reg [31:0] mem [0:15]; // 16-word, 32-bit register bank

    assign pready  = 1'b1; // Zero wait-state 
    assign pslverr = 1'b0; // No error responses generated

    // FSM State Register
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) state <= IDLE;
        else          state <= next_state;
    end

    // FSM Next-State Logic
    always @(*) begin
        case (state)
            IDLE:   next_state = psel ? SETUP : IDLE;
            SETUP:  next_state = (psel && penable) ? ACCESS : (psel ? SETUP : IDLE);
            ACCESS: next_state = psel ? SETUP : IDLE;
            default: next_state = IDLE;
        endcase
    end

    // Memory Read/Write Datapath
    integer i;
    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            prdata <= 32'h0;
            for (i = 0; i < 16; i = i + 1) mem[i] <= 32'h0;
        end else if (state == ACCESS && psel && penable) begin
            if (pwrite) mem[paddr] <= pwdata;     // Write
            else        prdata     <= mem[paddr]; // Read
        end
    end
endmodule