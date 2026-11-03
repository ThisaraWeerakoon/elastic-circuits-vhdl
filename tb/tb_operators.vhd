library ieee;
use ieee.std_logic_1164.all;

entity tb_operators is
end entity;

architecture sim of tb_operators is
  signal clk : std_logic := '0';
  signal rst : std_logic := '1';
  -- a_ = add, c_ = cmp, m_ = mul; l = lhs, r = rhs, res = result
  signal a_l, a_r, a_res                   : std_logic_vector(31 downto 0);
  signal a_l_v, a_l_r, a_r_v, a_r_r         : std_logic;
  signal a_res_v, a_res_r, a_done           : std_logic;
  signal c_l, c_r                          : std_logic_vector(31 downto 0);
  signal c_res                             : std_logic_vector(0 downto 0);
  signal c_l_v, c_l_r, c_r_v, c_r_r         : std_logic;
  signal c_res_v, c_res_r, c_done           : std_logic;
  signal m_l, m_r, m_res                   : std_logic_vector(31 downto 0);
  signal m_l_v, m_l_r, m_r_v, m_r_r         : std_logic;
  signal m_res_v, m_res_r, m_done           : std_logic;
begin
  clk <= not clk after 5 ns;
  rst <= '0' after 22 ns;

  -- add
  a_src_l: entity work.stim_source
    generic map (VALUES => (1, -5, 100, 7), VALID_PERCENT => 60, SEED => 91)
    port map (clk => clk, rst => rst, outs => a_l, outs_valid => a_l_v,
              outs_ready => a_l_r, done => open);
  a_src_r: entity work.stim_source
    generic map (VALUES => (2, 5, -1, -10), VALID_PERCENT => 40, SEED => 92)
    port map (clk => clk, rst => rst, outs => a_r, outs_valid => a_r_v,
              outs_ready => a_r_r, done => open);
  a_dut: entity work.add
    port map (clk => clk, rst => rst, lhs => a_l, lhs_valid => a_l_v, lhs_ready => a_l_r,
              rhs => a_r, rhs_valid => a_r_v, rhs_ready => a_r_r,
              result => a_res, result_valid => a_res_v, result_ready => a_res_r);
  a_snk: entity work.check_sink
    generic map (NAME => "add", EXPECTED => (3, 0, 99, -3), READY_PERCENT => 60, SEED => 93)
    port map (clk => clk, rst => rst, ins => a_res, ins_valid => a_res_v,
              ins_ready => a_res_r, done => a_done);

  -- cmp (signed less than)
  c_src_l: entity work.stim_source
    generic map (VALUES => (0, 5, -3, 7), VALID_PERCENT => 60, SEED => 101)
    port map (clk => clk, rst => rst, outs => c_l, outs_valid => c_l_v,
              outs_ready => c_l_r, done => open);
  c_src_r: entity work.stim_source
    generic map (VALUES => (5, 5, 0, 2), VALID_PERCENT => 60, SEED => 102)
    port map (clk => clk, rst => rst, outs => c_r, outs_valid => c_r_v,
              outs_ready => c_r_r, done => open);
  c_dut: entity work.cmp
    generic map (PREDICATE => "slt")
    port map (clk => clk, rst => rst, lhs => c_l, lhs_valid => c_l_v, lhs_ready => c_l_r,
              rhs => c_r, rhs_valid => c_r_v, rhs_ready => c_r_r,
              result => c_res, result_valid => c_res_v, result_ready => c_res_r);
  c_snk: entity work.check_sink
    generic map (NAME => "cmp_slt", DATA_WIDTH => 1, EXPECTED => (1, 0, 1, 0),
                 READY_PERCENT => 60, SEED => 103)
    port map (clk => clk, rst => rst, ins => c_res, ins_valid => c_res_v,
              ins_ready => c_res_r, done => c_done);

  -- mul (4-stage pipeline)
  m_src_l: entity work.stim_source
    generic map (VALUES => (3, -4, 0, 1000, 7, 65536), VALID_PERCENT => 80, SEED => 111)
    port map (clk => clk, rst => rst, outs => m_l, outs_valid => m_l_v,
              outs_ready => m_l_r, done => open);
  m_src_r: entity work.stim_source
    generic map (VALUES => (5, 6, 9, 1000, -1, 49152), VALID_PERCENT => 80, SEED => 112)
    port map (clk => clk, rst => rst, outs => m_r, outs_valid => m_r_v,
              outs_ready => m_r_r, done => open);
  m_dut: entity work.mul
    generic map (LATENCY => 4)
    port map (clk => clk, rst => rst, lhs => m_l, lhs_valid => m_l_v, lhs_ready => m_l_r,
              rhs => m_r, rhs_valid => m_r_v, rhs_ready => m_r_r,
              result => m_res, result_valid => m_res_v, result_ready => m_res_r);
  m_snk: entity work.check_sink
    generic map (NAME => "mul", EXPECTED => (15, -24, 0, 1000000, -7, -1073741824),
                 READY_PERCENT => 50, SEED => 113)
    port map (clk => clk, rst => rst, ins => m_res, ins_valid => m_res_v,
              ins_ready => m_res_r, done => m_done);

  finish: process
  begin
    wait until (a_done and c_done and m_done) = '1' for 20 us;
    assert (a_done and c_done and m_done) = '1' report "TIMEOUT" severity failure;
    report "tb_operators PASSED";
    std.env.finish;
  end process;
end architecture;
