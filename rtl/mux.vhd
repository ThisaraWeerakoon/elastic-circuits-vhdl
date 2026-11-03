library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.elastic_pkg.all;

-- Mux: an index token says which data input to take the next token from.
-- The index token and the chosen data token are consumed together.
entity mux is
  generic (
    SIZE         : positive := 2;
    DATA_WIDTH   : natural  := 32;
    SELECT_WIDTH : positive := 1
  );
  port (
    clk, rst    : in  std_logic;
    index       : in  std_logic_vector(SELECT_WIDTH - 1 downto 0);
    index_valid : in  std_logic;
    index_ready : out std_logic;
    ins         : in  data_array(SIZE - 1 downto 0)(DATA_WIDTH - 1 downto 0);
    ins_valid   : in  std_logic_vector(SIZE - 1 downto 0);
    ins_ready   : out std_logic_vector(SIZE - 1 downto 0);
    outs        : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    outs_valid  : out std_logic;
    outs_ready  : in  std_logic
  );
end entity;

architecture rtl of mux is
begin
  process (all)
    variable sel : natural;
  begin
    outs        <= ins(0);                  -- defaults
    outs_valid  <= '0';
    ins_ready   <= (others => '0');
    index_ready <= '0';
    if index_valid = '1' then
      sel := to_integer(unsigned(index));
      if sel < SIZE then
        outs           <= ins(sel);
        outs_valid     <= ins_valid(sel);
        ins_ready(sel) <= outs_ready;
        index_ready    <= ins_valid(sel) and outs_ready;
      end if;
    end if;
  end process;
end architecture;
