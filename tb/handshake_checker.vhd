library ieee;
use ieee.std_logic_1164.all;

-- Watches one valid/ready channel and reports protocol violations:
-- once valid is high and ready is low, valid must stay high and
-- data must stay the same until the transfer happens.
entity handshake_checker is
  generic (
    NAME       : string  := "channel";
    DATA_WIDTH : natural := 32
  );
  port (
    clk   : in std_logic;
    rst   : in std_logic;
    valid : in std_logic;
    ready : in std_logic;
    data  : in std_logic_vector(DATA_WIDTH - 1 downto 0)
  );
end entity;

architecture sim of handshake_checker is
begin
  process (clk)
    variable was_waiting : boolean := false;   -- valid=1, ready=0 at the last edge?
    variable last_data   : std_logic_vector(DATA_WIDTH - 1 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        was_waiting := false;
      else
        assert valid = '0' or valid = '1'
          report NAME & ": valid is " & std_logic'image(valid) severity error;
        if was_waiting then
          assert valid = '1'
            report NAME & ": valid dropped before the token was taken" severity error;
          assert data = last_data
            report NAME & ": data changed while waiting for ready" severity error;
        end if;
        was_waiting := (valid = '1' and ready = '0');
        last_data   := data;
      end if;
    end if;
  end process;
end architecture;
