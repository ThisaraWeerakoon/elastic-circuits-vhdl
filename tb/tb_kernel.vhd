library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_kernel is
  generic (
    KERNEL      : string   := "dynamic";   -- "dynamic" or "static"
    N           : positive := 16;
    POS_PERCENT : natural  := 50;          -- share of x values that are positive
    X_PERCENT   : natural  := 100;         -- chance the x source offers a value each cycle
    MUL_LATENCY : positive := 4;
    SEED        : positive := 1
  );
end entity;

architecture sim of tb_kernel is
  -- Random inputs: positive (1..3) with probability POS_PERCENT, else 0..-3.
  impure function make_inputs(count : positive; pos_share : natural; first_seed : positive)
    return integer_vector is
    variable xs : integer_vector(0 to count - 1);
    variable s1 : positive := first_seed;
    variable s2 : positive := 999;
    variable r  : real;
  begin
    for k in xs'range loop
      uniform(s1, s2, r);
      if r * 100.0 < real(pos_share) then
        uniform(s1, s2, r);
        xs(k) := 1 + integer(floor(r * 3.0));
      else
        uniform(s1, s2, r);
        xs(k) := -integer(floor(r * 4.0));
      end if;
    end loop;
    return xs;
  end function;

  -- Reference model: the C code, with C-style 32-bit wrap-around.
  function model(xs : integer_vector) return integer is
    variable s       : signed(31 downto 0) := to_signed(1, 32);
    variable xv      : signed(31 downto 0);
    variable product : signed(63 downto 0);
  begin
    for k in xs'range loop
      xv := to_signed(xs(k), 32);
      if xs(k) > 0 then
        product := s * xv;
        s := product(31 downto 0);
      else
        s := s + xv;
      end if;
    end loop;
    return to_integer(s);
  end function;

  constant XS         : integer_vector := make_inputs(N, POS_PERCENT, SEED);
  constant CLK_PERIOD : time := 10 ns;

  signal clk              : std_logic := '0';
  signal rst              : std_logic := '1';
  signal start            : std_logic_vector(0 downto 0);
  signal start_v, start_r : std_logic;
  signal x                : std_logic_vector(31 downto 0);
  signal x_v, x_r         : std_logic;
  signal res              : std_logic_vector(31 downto 0);
  signal res_v, res_r     : std_logic;
  signal done             : std_logic;
begin
  clk <= not clk after CLK_PERIOD / 2;
  rst <= '0' after 22 ns;

  start_src: entity work.stim_source
    generic map (DATA_WIDTH => 1, VALUES => (0 => 0), SEED => SEED)
    port map (clk => clk, rst => rst, outs => start, outs_valid => start_v,
              outs_ready => start_r, done => open);
  x_src: entity work.stim_source
    generic map (VALUES => XS, VALID_PERCENT => X_PERCENT, SEED => SEED + 1)
    port map (clk => clk, rst => rst, outs => x, outs_valid => x_v,
              outs_ready => x_r, done => open);

  gen_dynamic: if KERNEL = "dynamic" generate
    dut: entity work.kernel_dynamic
      generic map (N => N, MUL_LATENCY => MUL_LATENCY)
      port map (clk => clk, rst => rst, start_valid => start_v, start_ready => start_r,
                x => x, x_valid => x_v, x_ready => x_r,
                result => res, result_valid => res_v, result_ready => res_r);
  end generate;

  gen_static: if KERNEL = "static" generate
    dut: entity work.kernel_static
      generic map (N => N, MUL_LATENCY => MUL_LATENCY)
      port map (clk => clk, rst => rst, start_valid => start_v, start_ready => start_r,
                x => x, x_valid => x_v, x_ready => x_r,
                result => res, result_valid => res_v, result_ready => res_r);
  end generate;

  res_snk: entity work.check_sink
    generic map (NAME => "result", EXPECTED => (0 => model(XS)), SEED => SEED + 2)
    port map (clk => clk, rst => rst, ins => res, ins_valid => res_v,
              ins_ready => res_r, done => done);

  -- Cycles from the start token being accepted to the result being accepted.
  measure: process
    variable t_start : time;
  begin
    wait until rising_edge(clk) and start_v = '1' and start_r = '1';
    t_start := now;
    wait until rising_edge(clk) and res_v = '1' and res_r = '1';
    report "RESULT kernel=" & KERNEL & " n=" & integer'image(N)
         & " pos=" & integer'image(POS_PERCENT)
         & " cycles=" & integer'image((now - t_start) / CLK_PERIOD);
    wait;
  end process;

  finish: process
  begin
    wait until done = '1' for N * 20 * CLK_PERIOD + 1 us;
    assert done = '1' report "TIMEOUT: no result (deadlock?)" severity failure;
    report "tb_kernel PASSED";
    std.env.finish;
  end process;
end architecture;
