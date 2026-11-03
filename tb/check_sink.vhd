library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use work.elastic_pkg.all;

-- Receives tokens with a random ready signal, checks them in order
-- against EXPECTED, and checks the protocol on its input channel.
entity check_sink is
  generic (
    NAME          : string   := "sink";
    DATA_WIDTH    : natural  := 32;
    EXPECTED      : integer_vector;
    READY_PERCENT : natural  := 100;   -- chance (0-100) of being ready in a cycle
    SEED          : positive := 7
  );
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    ins       : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    ins_valid : in  std_logic;
    ins_ready : out std_logic;
    done      : out std_logic          -- '1' once every expected token arrived
  );
end entity;

architecture sim of check_sink is
  signal ready_i : std_logic := '0';   -- internal copy of ins_ready
begin
  ins_ready <= ready_i;

  checker: entity work.handshake_checker
    generic map (NAME => NAME, DATA_WIDTH => DATA_WIDTH)
    port map (clk => clk, rst => rst, valid => ins_valid, ready => ready_i, data => ins);

  process
    variable seed1 : positive := SEED;
    variable seed2 : positive := 54321;
    variable r     : real;
    variable count : natural := 0;
  begin
    done <= '0';
    wait until rising_edge(clk) and rst = '0';
    loop
      uniform(seed1, seed2, r);
      if r * 100.0 < real(READY_PERCENT) then
        ready_i <= '1';
      else
        ready_i <= '0';
      end if;
      wait until rising_edge(clk);
      if ins_valid = '1' and ready_i = '1' then       -- a transfer at this edge
        if count < EXPECTED'length then
          assert ins = to_slv(EXPECTED(EXPECTED'low + count), DATA_WIDTH)
            report NAME & ": token " & integer'image(count) & " expected "
                   & integer'image(EXPECTED(EXPECTED'low + count))
                   & ", got 0x" & to_hstring(ins)
            severity error;
        else
          report NAME & ": unexpected extra token 0x" & to_hstring(ins) severity error;
        end if;
        count := count + 1;
        if count = EXPECTED'length then
          done <= '1';
        end if;
      end if;
    end loop;
  end process;
end architecture;
