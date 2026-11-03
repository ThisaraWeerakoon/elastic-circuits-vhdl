library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use work.elastic_pkg.all;

-- Sends VALUES one by one on a valid/ready channel, with random idle
-- cycles between tokens.
entity stim_source is
  generic (
    DATA_WIDTH    : natural  := 32;
    VALUES        : integer_vector;
    VALID_PERCENT : natural  := 100;   -- chance (0-100) of offering a token in a cycle
    SEED          : positive := 1
  );
  port (
    clk        : in  std_logic;
    rst        : in  std_logic;
    outs       : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    outs_valid : out std_logic;
    outs_ready : in  std_logic;
    done       : out std_logic         -- '1' once every value has been taken
  );
end entity;

architecture sim of stim_source is
begin
  process
    variable seed1 : positive := SEED;
    variable seed2 : positive := 12345;
    variable r     : real;
  begin
    outs       <= (others => '0');
    outs_valid <= '0';
    done       <= '0';
    wait until rising_edge(clk) and rst = '0';
    for i in VALUES'range loop
      -- Random idle cycles before offering the next token.
      loop
        uniform(seed1, seed2, r);
        exit when r * 100.0 < real(VALID_PERCENT);
        outs_valid <= '0';
        wait until rising_edge(clk);
      end loop;
      -- Offer the token and hold it until it is taken.
      outs       <= to_slv(VALUES(i), DATA_WIDTH);
      outs_valid <= '1';
      loop
        wait until rising_edge(clk);
        exit when outs_ready = '1';   -- valid and ready at this edge: transferred
      end loop;
    end loop;
    outs_valid <= '0';
    done       <= '1';
    wait;
  end process;
end architecture;
