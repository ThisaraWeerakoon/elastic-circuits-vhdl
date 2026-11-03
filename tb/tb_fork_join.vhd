library ieee;
use ieee.std_logic_1164.all;
use work.elastic_pkg.all;

entity tb_fork_join is
end entity;

architecture sim of tb_fork_join is
  constant VALUES : integer_vector := (1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
  signal clk : std_logic := '0';
  signal rst : std_logic := '1';
  -- fork test
  signal f_in                    : std_logic_vector(31 downto 0);
  signal f_in_v, f_in_r          : std_logic;
  signal f_outs                  : data_array(2 downto 0)(31 downto 0);
  signal f_outs_v, f_outs_r      : std_logic_vector(2 downto 0);
  signal f_done                  : std_logic_vector(2 downto 0);
  -- join test
  signal j_a, j_b                : std_logic_vector(0 downto 0);
  signal j_in_v, j_in_r          : std_logic_vector(1 downto 0);
  signal j_out_v, j_out_r        : std_logic;
  signal j_done                  : std_logic;
begin
  clk <= not clk after 5 ns;
  rst <= '0' after 22 ns;

  -- Fork: one source, three sinks with different ready patterns
  f_src: entity work.stim_source
    generic map (VALUES => VALUES, VALID_PERCENT => 80, SEED => 41)
    port map (clk => clk, rst => rst, outs => f_in, outs_valid => f_in_v,
              outs_ready => f_in_r, done => open);
  f_dut: entity work.fork
    generic map (SIZE => 3)
    port map (clk => clk, rst => rst, ins => f_in, ins_valid => f_in_v, ins_ready => f_in_r,
              outs => f_outs, outs_valid => f_outs_v, outs_ready => f_outs_r);
  f_snk0: entity work.check_sink
    generic map (NAME => "fork_out0", EXPECTED => VALUES, READY_PERCENT => 90, SEED => 42)
    port map (clk => clk, rst => rst, ins => f_outs(0), ins_valid => f_outs_v(0),
              ins_ready => f_outs_r(0), done => f_done(0));
  f_snk1: entity work.check_sink
    generic map (NAME => "fork_out1", EXPECTED => VALUES, READY_PERCENT => 50, SEED => 43)
    port map (clk => clk, rst => rst, ins => f_outs(1), ins_valid => f_outs_v(1),
              ins_ready => f_outs_r(1), done => f_done(1));
  f_snk2: entity work.check_sink
    generic map (NAME => "fork_out2", EXPECTED => VALUES, READY_PERCENT => 20, SEED => 44)
    port map (clk => clk, rst => rst, ins => f_outs(2), ins_valid => f_outs_v(2),
              ins_ready => f_outs_r(2), done => f_done(2));

  -- Join: two control streams in, one out
  j_src_a: entity work.stim_source
    generic map (DATA_WIDTH => 1, VALUES => (0, 0, 0, 0, 0, 0), VALID_PERCENT => 40, SEED => 51)
    port map (clk => clk, rst => rst, outs => j_a, outs_valid => j_in_v(0),
              outs_ready => j_in_r(0), done => open);
  j_src_b: entity work.stim_source
    generic map (DATA_WIDTH => 1, VALUES => (0, 0, 0, 0, 0, 0), VALID_PERCENT => 70, SEED => 52)
    port map (clk => clk, rst => rst, outs => j_b, outs_valid => j_in_v(1),
              outs_ready => j_in_r(1), done => open);
  j_dut: entity work.join
    generic map (SIZE => 2)
    port map (ins_valid => j_in_v, ins_ready => j_in_r,
              outs_valid => j_out_v, outs_ready => j_out_r);
  j_snk: entity work.check_sink
    generic map (NAME => "join", DATA_WIDTH => 1, EXPECTED => (0, 0, 0, 0, 0, 0),
                 READY_PERCENT => 60, SEED => 53)
    port map (clk => clk, rst => rst, ins => "0", ins_valid => j_out_v,
              ins_ready => j_out_r, done => j_done);

  finish: process
  begin
    wait until (and f_done) = '1' and j_done = '1' for 20 us;
    assert (and f_done) = '1' and j_done = '1' report "TIMEOUT" severity failure;
    report "tb_fork_join PASSED";
    std.env.finish;
  end process;
end architecture;
