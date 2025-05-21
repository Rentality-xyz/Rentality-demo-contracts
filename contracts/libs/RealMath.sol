/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library RealMath {
  int128 constant REAL_BITS = 128;
  int128 constant REAL_FBITS = 40;

  int128 constant REAL_IBITS = REAL_BITS - REAL_FBITS;

  int128 public constant REAL_ONE = int128(1) << uint128(REAL_FBITS);

  int128 constant REAL_HALF = REAL_ONE >> 1;

  int128 constant REAL_TWO = REAL_ONE << 1;

  /**@dev
   * It is also useful to have Pi around.
   */
  int128 constant REAL_PI = 3454217652358;

  int128 constant REAL_HALF_PI = REAL_PI / 2;

  /**@dev
   * And two pi, which happens to be odd in its most accurate representation.
   */
  int128 constant REAL_TWO_PI = REAL_PI * 2;

  /**@dev
   * What's the sign bit?
   */
  int128 constant SIGN_MASK = int128(1) << 127;

  function RE_LN() internal pure returns (int128) {
    return int128(ln(2)) * int128((uint128(1) << uint128(int128(REAL_FBITS))));
  }

  /**
   * Convert an integer to a real. Preserves sign.
   */
  function toReal(int88 _ipart) internal pure returns (int128) {
    return int128(_ipart) * REAL_ONE;
  }

  /**
   * Convert a real to an integer. Preserves sign.
   */
  function fromReal(int128 real_value) internal pure returns (int88) {
    return int88(real_value / REAL_ONE);
  }

  /**
   * Round a real to the nearest integral real value.
   */
  function round(int128 real_value) internal pure returns (int128) {
    // First, truncate.
    int88 _ipart = fromReal(real_value);
    if ((fractionalBits(real_value) & (uint40(1) << uint40(uint128(REAL_FBITS - 1)))) > 0) {
      // High fractional bit is set. Round up.
      if (real_value < int128(0)) {
        // Rounding up for a negative number is rounding down.
        _ipart -= 1;
      } else {
        _ipart += 1;
      }
    }
    return toReal(_ipart);
  }

  /**
   * Get the absolute value of a real. Just the same as abs on a normal int128.
   */
  function abs(int128 real_value) internal pure returns (int128) {
    if (real_value > 0) {
      return real_value;
    } else {
      return -real_value;
    }
  }

  /**
   * Returns the fractional bits of a real. Ignores the sign of the real.
   */
  function fractionalBits(int128 real_value) internal pure returns (uint40) {
    return uint40(uint128(abs(real_value) % REAL_ONE));
  }

  /**
   * Get the fractional part of a real, as a real. Ignores sign (so fpart(-0.5) is 0.5).
   */
  function fpart(int128 real_value) internal pure returns (int128) {
    // This gets the fractional part but strips the sign
    return abs(real_value) % REAL_ONE;
  }

  /**
   * Get the fractional part of a real, as a real. Respects sign (so fpartSigned(-0.5) is -0.5).
   */
  function fpartSigned(int128 real_value) internal pure returns (int128) {
    // This gets the fractional part but strips the sign
    int128 fractional = fpart(real_value);
    if (real_value < 0) {
      // Add the negative sign back in.
      return -fractional;
    } else {
      return fractional;
    }
  }

  /**
   * Get the integer part of a fixed point value.
   */
  function ipart(int128 real_value) internal pure returns (int128) {
    // Subtract out the fractional part to get the real part.
    return real_value - fpartSigned(real_value);
  }

  /**
   * Multiply one real by another. Truncates overflows.
   */
  function mul(int128 real_a, int128 real_b) internal pure returns (int128) {
    // When multiplying fixed point in x.y and z.w formats we get (x+z).(y+w) format.
    // So we just have to clip off the extra REAL_FBITS fractional bits.
    return int128((real_a * real_b) >> uint128(REAL_FBITS));
  }

  /**
   * Divide one real by another real. Truncates overflows.
   */
  function div(int128 real_numerator, int128 real_denominator) internal pure returns (int128) {
    // We use the reverse of the multiplication trick: convert numerator from
    // x.y to (x+z).(y+w) fixed point, then divide by denom in z.w fixed point.
    return int128((int128(real_numerator) * REAL_ONE) / int128(real_denominator));
  }

  /**
   * Create a real from a rational fraction.
   */
  function fraction(int88 numerator, int88 denominator) internal pure returns (int128) {
    return div(toReal(numerator), toReal(denominator));
  }

  // Now we have some fancy math things (like pow and trig stuff). This isn't
  // in the RealMath that was deployed with the original Macroverse
  // deployment, so it needs to be linked into your contract statically.

  /**
   * Raise a number to a positive integer power in O(log power) time.
   * See <https://stackoverflow.com/a/101613>
   */
  function ipow(int128 real_base, int88 exponent) internal pure returns (int128) {
    if (exponent < 0) {
      // Negative powers are not allowed here.
      revert();
    }

    // Start with the 0th power
    int128 real_result = REAL_ONE;
    while (exponent != 0) {
      // While there are still bits set
      if ((exponent & 0x1) == 0x1) {
        // If the low bit is set, multiply in the (many-times-squared) base
        real_result = mul(real_result, real_base);
      }
      // Shift off the low bit
      exponent = exponent >> 1;
      // Do the squaring
      real_base = mul(real_base, real_base);
    }

    // Return the final result.
    return real_result;
  }

  /**
   * Zero all but the highest set bit of a number.
   * See <https://stackoverflow.com/a/53184>
   */
  function hibit(uint128 val) internal pure returns (uint128) {
    // Set all the bits below the highest set bit
    val |= (val >> 1);
    val |= (val >> 2);
    val |= (val >> 4);
    val |= (val >> 8);
    val |= (val >> 16);
    val |= (val >> 32);
    val |= (val >> 64);
    val |= (val >> 128);
    return val ^ (val >> 1);
  }

  /**
   * Given a number with one bit set, finds the index of that bit.
   */
  function findbit(uint128 val) internal pure returns (uint8 index) {
    index = 0;
    // We and the value with alternating bit patters of various pitches to find it.

    if (val & 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA != 0) {
      // Picth 1
      index |= 1;
    }
    if (val & 0xCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC != 0) {
      // Pitch 2
      index |= 2;
    }
    if (val & 0xF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0 != 0) {
      // Pitch 4
      index |= 4;
    }
    if (val & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00 != 0) {
      // Pitch 8
      index |= 8;
    }
    if (val & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000 != 0) {
      // Pitch 16
      index |= 16;
    }
    if (val & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000 != 0) {
      // Pitch 32
      index |= 32;
    }
    if (val & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000 != 0) {
      // Pitch 64
      index |= 64;
    }
    if (val & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000 != 0) {
      // Pitch 128
      index |= 128;
    }
  }

  /**
   * Shift real_arg left or right until it is between 1 and 2. Return the
   * rescaled value, and the number of bits of right shift applied. Shift may be negative.
   *
   * Expresses real_arg as real_scaled * 2^shift, setting shift to put real_arg between [1 and 2).
   *
   * Rejects 0 or negative arguments.
   */
  function rescale(int128 real_arg) internal pure returns (int128 real_scaled, int88 shift) {
    if (real_arg <= 0) {
      // Not in domain!
      revert();
    }

    uint8 finbit = findbit(hibit(uint128(real_arg)));
    int88 high_bit = int16(uint16(finbit));

    // We'll shift so the high bit is the lowest non-fractional bit.
    shift = high_bit - int88(REAL_FBITS);

    if (shift < 0) {
      // Negative shift means right shift
      real_scaled = int128(real_arg >> uint88(-shift));
    } else {
      // Positive shift means left shift
      real_scaled = int128(real_arg << uint88(shift));
    }
  }

  /**
   * Calculate the natural log of a number. Rescales the input value and uses
   * the algorithm outlined at <https://math.stackexchange.com/a/977836> and
   * the ipow implementation.
   *
   * Lets you artificially limit the number of iterations.
   *
   * Note that it is potentially possible to get an un-converged value; lack
   * of convergence does not throw.
   */
  function lnLimited(int128 real_arg, int max_iterations) internal pure returns (int128) {
    if (real_arg <= 0) {
      // Outside of acceptable domain
      revert();
    }

    if (real_arg == REAL_ONE) {
      // Handle this case specially because people will want exactly 0 and
      // not ~2^-39 ish.
      return 0;
    }

    // We know it's positive, so rescale it to be between [1 and 2)
    int128 real_rescaled;
    int88 shift;
    (real_rescaled, shift) = rescale(real_arg);

    // Compute the argument to iterate on
    int128 real_series_arg = div(real_rescaled - REAL_ONE, real_rescaled + REAL_ONE);

    // We will accumulate the result here
    int128 real_series_result = 0;

    for (int88 n = 0; n < max_iterations; n++) {
      // Compute term n of the series
      int128 real_term = div(ipow(real_series_arg, 2 * n + 1), toReal(2 * n + 1));
      // And add it in
      real_series_result += real_term;
      if (real_term == 0) {
        // We must have converged. Next term is too small to represent.
        break;
      }
      // If we somehow never converge I guess we will run out of gas
    }

    // Double it to account for the factor of 2 outside the sum
    real_series_result = mul(real_series_result, REAL_TWO);

    // Now compute and return the overall result
    return mul(toReal(shift), RE_LN()) + real_series_result;
  }

  /**
   * Calculate a natural logarithm with a sensible maximum iteration count to
   * wait until convergence. Note that it is potentially possible to get an
   * un-converged value; lack of convergence does not throw.
   */
  function ln(int128 real_arg) internal pure returns (int128) {
    return lnLimited(real_arg, 100);
  }

  function expLimited(int128 real_arg, int max_iterations) internal pure returns (int128) {
    // We will accumulate the result here
    int128 real_result = 0;

    // We use this to save work computing terms
    int128 real_term = REAL_ONE;

    for (int88 n = 0; n < max_iterations; n++) {
      // Add in the term
      real_result += real_term;

      // Compute the next term
      real_term = mul(real_term, div(real_arg, toReal(n + 1)));

      if (real_term == 0) {
        // We must have converged. Next term is too small to represent.
        break;
      }
      // If we somehow never converge I guess we will run out of gas
    }

    // Return the result
    return real_result;
  }

  /**
   * Calculate e^x with a sensible maximum iteration count to wait until
   * convergence. Note that it is potentially possible to get an un-converged
   * value; lack of convergence does not throw.
   */
  function exp(int128 real_arg) internal pure returns (int128) {
    return expLimited(real_arg, 100);
  }

  /**
   * Raise any number to any power, except for negative bases to fractional powers.
   */
  function pow(int128 real_base, int128 real_exponent) internal pure returns (int128) {
    if (real_exponent == 0) {
      // Anything to the 0 is 1
      return REAL_ONE;
    }

    if (real_base == 0) {
      if (real_exponent < 0) {
        // Outside of domain!
        revert();
      }
      // Otherwise it's 0
      return 0;
    }

    if (fpart(real_exponent) == 0) {
      // Anything (even a negative base) is super easy to do to an integer power.

      if (real_exponent > 0) {
        // Positive integer power is easy
        return ipow(real_base, fromReal(real_exponent));
      } else {
        // Negative integer power is harder
        return div(REAL_ONE, ipow(real_base, fromReal(-real_exponent)));
      }
    }

    if (real_base < 0) {
      // It's a negative base to a non-integer power.
      // In general pow(-x^y) is undefined, unless y is an int or some
      // weird rational-number-based relationship holds.
      revert();
    }

    // If it's not a special case, actually do it.
    return exp(mul(real_exponent, ln(real_base)));
  }

  /**
   * Compute the square root of a number.
   */
  function sqrt(int128 real_arg) internal pure returns (int128) {
    return pow(real_arg, REAL_HALF);
  }

  function sinLimited(int128 real_arg, int88 max_iterations) internal pure returns (int128) {
    // Ensure real_arg is within 0 to 2π
    if (real_arg < 0) {
      real_arg += REAL_TWO_PI; // Make positive if negative
    }
    real_arg = real_arg % REAL_TWO_PI;

    int128 accumulator = REAL_ONE;

    // Check that max_iterations is a reasonable value
    require(max_iterations > 0 && max_iterations <= 70, 'Invalid iteration count');

    // Taylor series approximation with reverse iteration
    for (int88 iteration = max_iterations - 1; iteration >= 0; iteration--) {
      // Avoid division by zero or overflow issues
      int128 denominator = toReal((2 * iteration + 2) * (2 * iteration + 3));
      if (denominator == 0) {
        continue; // Skip if division by zero risk
      }

      int128 term = div(mul(real_arg, real_arg), denominator);
      accumulator = REAL_ONE - mul(term, accumulator);
    }

    // Multiply by the angle to get the sine approximation
    return mul(real_arg, accumulator);
  }

  /**
   * Calculate sin(x) with a sensible maximum iteration count to wait until
   * convergence.
   */
  function sin(int128 real_arg) internal pure returns (int128) {
    return sinLimited(real_arg, 15);
  }

  /**
   * Calculate cos(x).
   */
  function cos(int128 real_arg) internal pure returns (int128) {
    return sin(real_arg + REAL_HALF_PI);
  }

  /**
   * Calculate tan(x). May overflow for large results. May throw if tan(x)
   * would be infinite, or return an approximation, or overflow.
   */
  function tan(int128 real_arg) internal pure returns (int128) {
    return div(sin(real_arg), cos(real_arg));
  }

  /**
   * Calculate atan(x) for x in [-1, 1].
   * Uses the Chebyshev polynomial approach presented at
   * https://www.mathworks.com/help/fixedpoint/examples/calculate-fixed-point-arctangent.html
   * Uses polynomials received by personal communication.
   * 0.999974x-0.332568x^3+0.193235x^5-0.115729x^7+0.0519505x^9-0.0114658x^11
   */
  function atanSmall(int128 real_arg) internal pure returns (int128) {
    int128 real_arg_squared = mul(real_arg, real_arg);
    return
      mul(
        mul(
          mul(
            mul(
              mul(
                mul(-12606780422, real_arg_squared) + 57120178819, // x^11
                real_arg_squared
              ) - 127245381171, // x^9
              real_arg_squared
            ) + 212464129393, // x^7
            real_arg_squared
          ) - 365662383026, // x^5
          real_arg_squared
        ) + 1099483040474, // x^3
        real_arg
      ); // x^1
  }

  function atan2(int128 real_y, int128 real_x) internal pure returns (int128) {
    int128 atan_result;

    // Do the angle correction shown at
    // https://www.mathworks.com/help/fixedpoint/examples/calculate-fixed-point-arctangent.html

    // We will re-use these absolute values
    int128 real_abs_x = abs(real_x);
    int128 real_abs_y = abs(real_y);

    if (real_abs_x > real_abs_y) {
      // We are in the (0, pi/4] region
      // abs(y)/abs(x) will be in 0 to 1.
      atan_result = atanSmall(div(real_abs_y, real_abs_x));
    } else {
      // We are in the (pi/4, pi/2) region
      // abs(x) / abs(y) will be in 0 to 1; we swap the arguments
      atan_result = REAL_HALF_PI - atanSmall(div(real_abs_x, real_abs_y));
    }

    // Now we correct the result for other regions
    if (real_x < 0) {
      if (real_y < 0) {
        atan_result -= REAL_PI;
      } else {
        atan_result = REAL_PI - atan_result;
      }
    } else {
      if (real_y < 0) {
        atan_result = -atan_result;
      }
    }

    return atan_result;
  }

  // needed, because sqrt works slow
  function sqrt1(uint128 x) internal pure returns (uint128 y) {
    uint128 z = (x + 1) / 2;
    y = x;
    while (z < y) {
      y = z;
      z = (x / z + z) / 2;
    }
  }
}
