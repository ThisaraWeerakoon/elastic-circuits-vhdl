library ieee;
use ieee.std_logic_1164.all;
use work.elastic_pkg.all;

-- Turns each control token into a token carrying VALUE.
entity const is
  generic (
    DATA_WIDTH : natural := 32;
    VALUE      : integer := 0
  );
  port (
    clk, rst   : in  std_logic;
    ctrl_valid : in  std_logic;    -- control channel: valid/ready only
    ctrl_ready : out std_logic;
    outs       : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    outs_valid : out std_logic;
    outs_ready : in  std_logic
  );
end entity;

architecture rtl of const is
begin
  outs       <= to_slv(VALUE, DATA_WIDTH);
  outs_valid <= ctrl_valid;
  ctrl_ready <= outs_ready;
end architecture;
