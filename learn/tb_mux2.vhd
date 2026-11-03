library ieee;
use ieee.std_logic_1164.all;

entity tb_mux2 is
end entity;                      -- no ports: a testbench is the whole world

architecture sim of tb_mux2 is
  signal a, b, y : std_logic_vector(7 downto 0);
  signal sel     : std_logic;
begin
  -- Place the design and connect its ports (left) to our signals (right).
  dut: entity work.mux2
    port map (a => a, b => b, sel => sel, y => y);

  stimulus: process
  begin
    a <= x"11"; b <= x"22"; sel <= '0';
    wait for 10 ns;
    assert y = x"11" report "sel=0 should pick a" severity error;

    sel <= '1';
    wait for 10 ns;
    assert y = x"22" report "sel=1 should pick b" severity error;

    report "tb_mux2 finished";
    wait;                        -- a bare wait stops this process forever
  end process;
end architecture;
