library ieee;
use ieee.std_logic_1164.all;

-- Offers a dataless token every cycle, forever.
entity source is
  port (
    clk, rst   : in  std_logic;
    outs_valid : out std_logic;
    outs_ready : in  std_logic
  );
end entity;

architecture rtl of source is
begin
  outs_valid <= '1';
end architecture;
