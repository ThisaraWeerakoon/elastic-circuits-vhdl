library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Statically scheduled version of the same kernel: every iteration takes
-- 1 + MUL_LATENCY cycles, because the schedule is fixed for the slow path.
-- Same ports as kernel_dynamic.
entity kernel_static is
  generic (
    N           : positive := 16;
    MUL_LATENCY : positive := 4
  );
  port (
    clk, rst     : in  std_logic;
    start_valid  : in  std_logic;
    start_ready  : out std_logic;
    x            : in  std_logic_vector(31 downto 0);
    x_valid      : in  std_logic;
    x_ready      : out std_logic;
    result       : out std_logic_vector(31 downto 0);
    result_valid : out std_logic;
    result_ready : in  std_logic
  );
end entity;

architecture rtl of kernel_static is
  type state_t is (IDLE, FETCH, COMPUTE, DONE);
  signal state    : state_t;
  signal i        : natural range 0 to N;
  signal wait_cnt : natural range 0 to MUL_LATENCY;
  signal s        : signed(31 downto 0);
  signal x_r      : signed(31 downto 0);
begin
  start_ready  <= '1' when state = IDLE  else '0';
  x_ready      <= '1' when state = FETCH else '0';
  result_valid <= '1' when state = DONE  else '0';
  result       <= std_logic_vector(s);

  process (clk)
    variable product : signed(63 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        state <= IDLE;
      else
        case state is
          when IDLE =>
            if start_valid = '1' then
              s     <= to_signed(1, 32);
              i     <= 0;
              state <= FETCH;
            end if;

          when FETCH =>                         -- 1 cycle: take x[i]
            if x_valid = '1' then
              x_r      <= signed(x);
              wait_cnt <= 1;
              state    <= COMPUTE;
            end if;

          when COMPUTE =>                       -- MUL_LATENCY cycles, whatever x is
            if wait_cnt = MUL_LATENCY then
              if x_r > 0 then
                product := s * x_r;
                s <= product(31 downto 0);
              else
                s <= s + x_r;
              end if;
              if i = N - 1 then
                state <= DONE;
              else
                i     <= i + 1;
                state <= FETCH;
              end if;
            else
              wait_cnt <= wait_cnt + 1;
            end if;

          when DONE =>                          -- hold the result until taken
            if result_ready = '1' then
              state <= IDLE;
            end if;
        end case;
      end if;
    end if;
  end process;
end architecture;
