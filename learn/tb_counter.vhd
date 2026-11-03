library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_counter is
end entity;

architecture sim of tb_counter is
  constant CLK_PERIOD : time := 10 ns;
  signal clk    : std_logic := '0';      -- initial value, so "not clk" works
  signal rst    : std_logic := '1';
  signal enable : std_logic := '0';
  signal count  : std_logic_vector(3 downto 0);
begin
  clk <= not clk after CLK_PERIOD / 2;   -- toggles every 5 ns, forever

  dut: entity work.counter
    generic map (WIDTH => 4)
    port map (clk => clk, rst => rst, enable => enable, count => count);

  stimulus: process
  begin
    wait for 2 * CLK_PERIOD;             -- keep reset on for two clock edges
    rst    <= '0';
    enable <= '1';
    for i in 1 to 20 loop                -- let 20 rising edges pass
      wait until rising_edge(clk);
    end loop;
    wait for 1 ns;                       -- let the register output settle
    -- 20 increments of a 4-bit counter wrap around: 20 mod 16 = 4
    assert to_integer(unsigned(count)) = 4
      report "expected 4, got " & integer'image(to_integer(unsigned(count)))
      severity error;
    report "tb_counter finished";
    std.env.finish;                      -- end the simulation
  end process;
end architecture;
