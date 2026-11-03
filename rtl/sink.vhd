library ieee;
use ieee.std_logic_1164.all;

-- Accepts every token and throws it away.
entity sink is
  generic (
    DATA_WIDTH : natural := 32
  );
  port (
    clk, rst  : in  std_logic;
    ins       : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    ins_valid : in  std_logic;
    ins_ready : out std_logic
  );
end entity;

architecture rtl of sink is
begin
  ins_ready <= '1';                -- always ready
end architecture;
