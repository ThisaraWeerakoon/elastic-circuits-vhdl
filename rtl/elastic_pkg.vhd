library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package elastic_pkg is
  -- Several data buses side by side, e.g. the outputs of a fork.
  -- Both the number of buses and their width are chosen where it is used.
  type data_array is array (natural range <>) of std_logic_vector;

  -- Integer to bit pattern. Negative values use two's complement.
  function to_slv(value : integer; width : natural) return std_logic_vector;
end package;

package body elastic_pkg is
  function to_slv(value : integer; width : natural) return std_logic_vector is
  begin
    if value < 0 then
      return std_logic_vector(to_signed(value, width));
    else
      return std_logic_vector(to_unsigned(value, width));
    end if;
  end function;
end package body;
