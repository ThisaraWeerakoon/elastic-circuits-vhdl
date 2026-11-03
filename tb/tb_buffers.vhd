library ieee;
use ieee.std_logic_1164.all;

entity tb_buffers is
end entity;

architecture sim of tb_buffers is
  constant VALUES : integer_vector := (10, 20, 30, 40, 50, 60, 70, 80, -1, -2, -3, 0);
  signal clk : std_logic := '0';
  signal rst : std_logic := '1';
  -- o_ = oehb, t_ = tehb, f_ = fifo; _v = valid, _r = ready
  signal o_in, o_out, t_in, t_out, f_in, f_out : std_logic_vector(31 downto 0);
  signal o_in_v, o_in_r, o_out_v, o_out_r      : std_logic;
  signal t_in_v, t_in_r, t_out_v, t_out_r      : std_logic;
  signal f_in_v, f_in_r, f_out_v, f_out_r      : std_logic;
  signal o_done, t_done, f_done                : std_logic;
begin
  clk <= not clk after 5 ns;
  rst <= '0' after 22 ns;

  o_src: entity work.stim_source
    generic map (VALUES => VALUES, VALID_PERCENT => 70, SEED => 11)
    port map (clk => clk, rst => rst, outs => o_in, outs_valid => o_in_v,
              outs_ready => o_in_r, done => open);
  o_dut: entity work.oehb
    port map (clk => clk, rst => rst, ins => o_in, ins_valid => o_in_v, ins_ready => o_in_r,
              outs => o_out, outs_valid => o_out_v, outs_ready => o_out_r);
  o_snk: entity work.check_sink
    generic map (NAME => "oehb", EXPECTED => VALUES, READY_PERCENT => 60, SEED => 12)
    port map (clk => clk, rst => rst, ins => o_out, ins_valid => o_out_v,
              ins_ready => o_out_r, done => o_done);

  t_src: entity work.stim_source
    generic map (VALUES => VALUES, VALID_PERCENT => 70, SEED => 21)
    port map (clk => clk, rst => rst, outs => t_in, outs_valid => t_in_v,
              outs_ready => t_in_r, done => open);
  t_dut: entity work.tehb
    port map (clk => clk, rst => rst, ins => t_in, ins_valid => t_in_v, ins_ready => t_in_r,
              outs => t_out, outs_valid => t_out_v, outs_ready => t_out_r);
  t_snk: entity work.check_sink
    generic map (NAME => "tehb", EXPECTED => VALUES, READY_PERCENT => 60, SEED => 22)
    port map (clk => clk, rst => rst, ins => t_out, ins_valid => t_out_v,
              ins_ready => t_out_r, done => t_done);

  f_src: entity work.stim_source
    generic map (VALUES => VALUES, VALID_PERCENT => 70, SEED => 31)
    port map (clk => clk, rst => rst, outs => f_in, outs_valid => f_in_v,
              outs_ready => f_in_r, done => open);
  f_dut: entity work.fifo
    generic map (DEPTH => 3)
    port map (clk => clk, rst => rst, ins => f_in, ins_valid => f_in_v, ins_ready => f_in_r,
              outs => f_out, outs_valid => f_out_v, outs_ready => f_out_r);
  f_snk: entity work.check_sink
    generic map (NAME => "fifo", EXPECTED => VALUES, READY_PERCENT => 60, SEED => 32)
    port map (clk => clk, rst => rst, ins => f_out, ins_valid => f_out_v,
              ins_ready => f_out_r, done => f_done);

  finish: process
  begin
    wait until (o_done and t_done and f_done) = '1' for 20 us;
    assert (o_done and t_done and f_done) = '1' report "TIMEOUT" severity failure;
    report "tb_buffers PASSED";
    std.env.finish;
  end process;
end architecture;
