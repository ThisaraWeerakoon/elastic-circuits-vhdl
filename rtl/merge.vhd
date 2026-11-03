library ieee;
use ieee.std_logic_1164.all;
use work.elastic_pkg.all;

-- Merge: forwards a token from whichever input has one (the lowest
-- index wins if several do). Safe only when at most one input can
-- hold a token at a time.
entity merge is
  generic (
    SIZE       : positive := 2;
    DATA_WIDTH : natural  := 32
  );
  port (
    clk, rst   : in  std_logic;
    ins        : in  data_array(SIZE - 1 downto 0)(DATA_WIDTH - 1 downto 0);
    ins_valid  : in  std_logic_vector(SIZE - 1 downto 0);
    ins_ready  : out std_logic_vector(SIZE - 1 downto 0);
    outs       : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    outs_valid : out std_logic;
    outs_ready : in  std_logic
  );
end entity;

architecture rtl of merge is
begin
  process (all)
    variable found : boolean;
  begin
    outs       <= ins(0);                   -- defaults
    outs_valid <= '0';
    ins_ready  <= (others => '0');
    found      := false;
    for i in 0 to SIZE - 1 loop
      if not found and ins_valid(i) = '1' then
        found        := true;
        outs         <= ins(i);
        outs_valid   <= '1';
        ins_ready(i) <= outs_ready;
      end if;
    end loop;
  end process;
end architecture;
