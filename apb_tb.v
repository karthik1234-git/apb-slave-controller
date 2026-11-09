`timescale 1ns/1ps

module apb_tb;
    reg pclk, presetn, psel, penable, pwrite;
    reg [3:0] paddr;
    reg [31:0] pwdata;
    wire [31:0] prdata;
    wire pready, pslverr;

    apb dut (
        .pclk(pclk), .presetn(presetn), .psel(psel), .penable(penable),
        .pwrite(pwrite), .paddr(paddr), .pwdata(pwdata),
        .prdata(prdata), .pready(pready), .pslverr(pslverr)
    );

    // Clock Generation
    initial pclk = 0;
    always #5 pclk = ~pclk;

    // APB Write Task
    task apb_write(input [3:0] addr, input [31:0] data);
        begin
            @(posedge pclk);
            psel = 1; pwrite = 1; paddr = addr; pwdata = data; penable = 0; // SETUP
            @(posedge pclk);
            penable = 1; // ACCESS
            @(posedge pclk);
            wait(pready);
            psel = 0; penable = 0; pwrite = 0;
        end
    endtask

    // APB Read Task
    task apb_read(input [3:0] addr);
        begin
            @(posedge pclk);
            psel = 1; pwrite = 0; paddr = addr; penable = 0; // SETUP
            @(posedge pclk);
            penable = 1; // ACCESS
            @(posedge pclk);
            wait(pready);
            psel = 0; penable = 0;
        end
    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, apb_tb);

        // Reset
        presetn = 0; psel = 0; penable = 0; pwrite = 0; paddr = 0; pwdata = 0;
        #20 presetn = 1;

        // Test Sequence
        #10 apb_write(4'h4, 32'hDEADBEEF);
        #10 apb_write(4'h8, 32'hCAFEBABE);
        #10 apb_read(4'h4);
        #10 apb_read(4'h8);
        #20 $finish;
    end
endmodule