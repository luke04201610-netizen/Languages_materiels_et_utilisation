-- Small helpers for the generic blocks

package util_pkg is

  -- number of bits needed to number n items: log2ceil(4) = 2, log2ceil(5) = 3
  -- (computed on integers: ceil(log2(real(n))) of math_real may be rounded up wrongly)
  function log2ceil(n : positive) return natural;

end package util_pkg;

package body util_pkg is

  function log2ceil(n : positive) return natural is
    variable bits : natural := 0;
  begin
    while 2**bits < n loop
      bits := bits + 1;
    end loop;
    return bits;
  end function log2ceil;

end package body util_pkg;
