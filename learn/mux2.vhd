library ieee;
use ieee.std_logic_1164.all;     -- gives us std_logic and std_logic_vector

entity mux2 is
  port (
    a   : in  std_logic_vector(7 downto 0);
    b   : in  std_logic_vector(7 downto 0);
    sel : in  std_logic;
    y   : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of mux2 is
begin
  -- A concurrent assignment: this line IS a mux circuit.
  y <= a when sel = '0' else b;
end architecture;
