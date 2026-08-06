// Blackbox stub for the hardened top_pd_min macro (PUF-derived-key secure
// boot RoT). Port list matches the real post-PnR netlist exactly (see
// opentitan_minrot_nix/verilog/gl/top_pd_min.nl.v) -- no VDD/VSS ports,
// power is supplied through the macro's physical LEF pins via the padring
// PDN, same as the id/logo macros in this repo.
module top_pd_min (
    clk_i,
    rst_ni,
    uart_rx_i,
    uart_tx_en_o,
    uart_tx_o
);
    input  clk_i;
    input  rst_ni;
    input  uart_rx_i;
    output uart_tx_en_o;
    output uart_tx_o;
endmodule
