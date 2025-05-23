# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2021 The Elixir Team
# SPDX-FileCopyrightText: 2012 Plataformatec

defmodule Integer do
  @moduledoc """
  Functions for working with integers.

  Some functions that work on integers are found in `Kernel`:

    * `Kernel.abs/1`
    * `Kernel.div/2`
    * `Kernel.max/2`
    * `Kernel.min/2`
    * `Kernel.rem/2`

  """

  import Bitwise

  @doc """
  Determines if `integer` is odd.

  Returns `true` if the given `integer` is an odd number,
  otherwise it returns `false`.

  Allowed in guard clauses.

  ## Examples

      iex> Integer.is_odd(5)
      true

      iex> Integer.is_odd(6)
      false

      iex> Integer.is_odd(-5)
      true

      iex> Integer.is_odd(0)
      false

  """
  defguard is_odd(integer) when is_integer(integer) and (integer &&& 1) == 1

  @doc """
  Determines if an `integer` is even.

  Returns `true` if the given `integer` is an even number,
  otherwise it returns `false`.

  Allowed in guard clauses.

  ## Examples

      iex> Integer.is_even(10)
      true

      iex> Integer.is_even(5)
      false

      iex> Integer.is_even(-10)
      true

      iex> Integer.is_even(0)
      true

  """
  defguard is_even(integer) when is_integer(integer) and (integer &&& 1) == 0

  @doc """
  Computes `base` raised to power of `exponent`.

  Both `base` and `exponent` must be integers.
  The exponent must be zero or positive.

  See `Float.pow/2` for exponentiation of negative
  exponents as well as floats.

  ## Examples

      iex> Integer.pow(2, 0)
      1
      iex> Integer.pow(2, 1)
      2
      iex> Integer.pow(2, 10)
      1024
      iex> Integer.pow(2, 11)
      2048
      iex> Integer.pow(2, 64)
      0x10000000000000000

      iex> Integer.pow(3, 4)
      81
      iex> Integer.pow(4, 3)
      64

      iex> Integer.pow(-2, 3)
      -8
      iex> Integer.pow(-2, 4)
      16

      iex> Integer.pow(2, -2)
      ** (ArithmeticError) bad argument in arithmetic expression

  """
  @doc since: "1.12.0"
  @spec pow(integer, non_neg_integer) :: integer
  def pow(base, exponent) when is_integer(base) and is_integer(exponent) do
    if exponent < 0, do: :erlang.error(:badarith, [base, exponent])
    base ** exponent
  end

  @doc """
  Computes the modulo remainder of an integer division.

  This function performs a [floored division](`floor_div/2`), which means that
  the result will always have the sign of the `divisor`.

  Raises an `ArithmeticError` exception if one of the arguments is not an
  integer, or when the `divisor` is `0`.

  ## Examples

      iex> Integer.mod(5, 2)
      1
      iex> Integer.mod(6, -4)
      -2

  """
  @doc since: "1.4.0"
  @spec mod(integer, neg_integer | pos_integer) :: integer
  def mod(dividend, divisor) do
    remainder = rem(dividend, divisor)

    if remainder * divisor < 0 do
      remainder + divisor
    else
      remainder
    end
  end

  @doc """
  Performs a floored integer division.

  Raises an `ArithmeticError` exception if one of the arguments is not an
  integer, or when the `divisor` is `0`.

  This function performs a *floored* integer division, which means that
  the result will always be rounded towards negative infinity.

  If you want to perform truncated integer division (rounding towards zero),
  use `Kernel.div/2` instead.

  ## Examples

      iex> Integer.floor_div(5, 2)
      2
      iex> Integer.floor_div(6, -4)
      -2
      iex> Integer.floor_div(-99, 2)
      -50

  """
  @doc since: "1.4.0"
  @spec floor_div(integer, neg_integer | pos_integer) :: integer
  def floor_div(dividend, divisor) do
    if :erlang.xor(dividend < 0, divisor < 0) and rem(dividend, divisor) != 0 do
      div(dividend, divisor) - 1
    else
      div(dividend, divisor)
    end
  end

  @doc """
  Returns the ordered digits for the given `integer`.

  An optional `base` value may be provided representing the radix for the returned
  digits. This one must be an integer >= 2.

  ## Examples

      iex> Integer.digits(123)
      [1, 2, 3]

      iex> Integer.digits(170, 2)
      [1, 0, 1, 0, 1, 0, 1, 0]

      iex> Integer.digits(-170, 2)
      [-1, 0, -1, 0, -1, 0, -1, 0]

  """
  @spec digits(integer, pos_integer) :: [integer, ...]
  def digits(integer, base \\ 10)
      when is_integer(integer) and is_integer(base) and base >= 2 do
    case integer do
      0 -> [0]
      _integer -> digits(integer, base, [])
    end
  end

  defp digits(0, _base, acc), do: acc

  defp digits(integer, base, acc),
    do: digits(div(integer, base), base, [rem(integer, base) | acc])

  @doc """
  Returns the integer represented by the ordered `digits`.

  An optional `base` value may be provided representing the radix for the `digits`.
  Base has to be an integer greater than or equal to `2`.

  ## Examples

      iex> Integer.undigits([1, 2, 3])
      123

      iex> Integer.undigits([1, 4], 16)
      20

      iex> Integer.undigits([])
      0

  """
  @spec undigits([integer], pos_integer) :: integer
  def undigits(digits, base \\ 10) when is_list(digits) and is_integer(base) and base >= 2 do
    undigits(digits, base, 0)
  end

  defp undigits([], _base, acc), do: acc

  defp undigits([digit | _], base, _) when is_integer(digit) and digit >= base,
    do: raise(ArgumentError, "invalid digit #{digit} in base #{base}")

  defp undigits([digit | tail], base, acc) when is_integer(digit),
    do: undigits(tail, base, acc * base + digit)

  @doc """
  Parses a text representation of an integer.

  An optional `base` to the corresponding integer can be provided.
  If `base` is not given, 10 will be used.

  If successful, returns a tuple in the form of `{integer, remainder_of_binary}`.
  Otherwise `:error`.

  Raises an error if `base` is less than 2 or more than 36.

  If you want to convert a string-formatted integer directly to an integer,
  `String.to_integer/1` or `String.to_integer/2` can be used instead.

  ## Examples

      iex> Integer.parse("34")
      {34, ""}

      iex> Integer.parse("34.5")
      {34, ".5"}

      iex> Integer.parse("three")
      :error

      iex> Integer.parse("34", 10)
      {34, ""}

      iex> Integer.parse("f4", 16)
      {244, ""}

      iex> Integer.parse("Awww++", 36)
      {509216, "++"}

      iex> Integer.parse("fab", 10)
      :error

      iex> Integer.parse("a2", 38)
      ** (ArgumentError) invalid base 38

  """
  @spec parse(binary, 2..36) :: {integer, remainder_of_binary :: binary} | :error
  def parse(binary, base \\ 10)

  def parse(_binary, base) when base not in 2..36 do
    raise ArgumentError, "invalid base #{inspect(base)}"
  end

  def parse(binary, base) when is_binary(binary) do
    case count_digits(binary, base) do
      0 ->
        :error

      count ->
        {digits, rem} = :erlang.split_binary(binary, count)
        {:erlang.binary_to_integer(digits, base), rem}
    end
  end

  defp count_digits(<<sign, rest::bits>>, base) when sign in ~c"+-" do
    case count_digits_nosign(rest, base, 1) do
      1 -> 0
      count -> count
    end
  end

  defp count_digits(<<rest::bits>>, base) do
    count_digits_nosign(rest, base, 0)
  end

  digits = [{?0..?9, -?0}, {?A..?Z, 10 - ?A}, {?a..?z, 10 - ?a}]

  for {chars, diff} <- digits,
      char <- chars do
    digit = char + diff

    defp count_digits_nosign(<<unquote(char), rest::bits>>, base, count)
         when base > unquote(digit) do
      count_digits_nosign(rest, base, count + 1)
    end
  end

  defp count_digits_nosign(<<_::bits>>, _, count), do: count

  @doc """
  Returns a binary which corresponds to the text representation
  of `integer` in the given `base`.

  `base` can be an integer between 2 and 36. If no `base` is given,
  it defaults to `10`.

  Inlined by the compiler.

  ## Examples

      iex> Integer.to_string(123)
      "123"

      iex> Integer.to_string(+456)
      "456"

      iex> Integer.to_string(-789)
      "-789"

      iex> Integer.to_string(0123)
      "123"

      iex> Integer.to_string(100, 16)
      "64"

      iex> Integer.to_string(-100, 16)
      "-64"

      iex> Integer.to_string(882_681_651, 36)
      "ELIXIR"

  """
  @spec to_string(integer, 2..36) :: String.t()
  def to_string(integer, base \\ 10) do
    :erlang.integer_to_binary(integer, base)
  end

  @doc """
  Returns a charlist which corresponds to the text representation
  of `integer` in the given `base`.

  `base` can be an integer between 2 and 36. If no `base` is given,
  it defaults to `10`.

  Inlined by the compiler.

  ## Examples

      iex> Integer.to_charlist(123)
      ~c"123"

      iex> Integer.to_charlist(+456)
      ~c"456"

      iex> Integer.to_charlist(-789)
      ~c"-789"

      iex> Integer.to_charlist(0123)
      ~c"123"

      iex> Integer.to_charlist(100, 16)
      ~c"64"

      iex> Integer.to_charlist(-100, 16)
      ~c"-64"

      iex> Integer.to_charlist(882_681_651, 36)
      ~c"ELIXIR"

  """
  @spec to_charlist(integer, 2..36) :: charlist
  def to_charlist(integer, base \\ 10) do
    :erlang.integer_to_list(integer, base)
  end

  @doc """
  Returns the greatest common divisor of the two given integers.

  The greatest common divisor (GCD) of `integer1` and `integer2` is the largest positive
  integer that divides both `integer1` and `integer2` without leaving a remainder.

  By convention, `gcd(0, 0)` returns `0`.

  ## Examples

      iex> Integer.gcd(2, 3)
      1

      iex> Integer.gcd(8, 12)
      4

      iex> Integer.gcd(8, -12)
      4

      iex> Integer.gcd(10, 0)
      10

      iex> Integer.gcd(7, 7)
      7

      iex> Integer.gcd(0, 0)
      0

  """
  @doc since: "1.5.0"
  @spec gcd(integer, integer) :: non_neg_integer
  def gcd(integer1, integer2) when is_integer(integer1) and is_integer(integer2) do
    gcd_positive(abs(integer1), abs(integer2))
  end

  defp gcd_positive(0, integer2), do: integer2
  defp gcd_positive(integer1, 0), do: integer1
  defp gcd_positive(integer1, integer2), do: gcd_positive(integer2, rem(integer1, integer2))

  @doc """
  Returns the extended greatest common divisor of the two given integers.

  This function uses the extended Euclidean algorithm to return a three-element tuple with the `gcd`
  and the coefficients `m` and `n` of Bézout's identity such that:

      gcd(a, b) = m*a + n*b

  By convention, `extended_gcd(0, 0)` returns `{0, 0, 0}`.

  ## Examples

      iex> Integer.extended_gcd(240, 46)
      {2, -9, 47}
      iex> Integer.extended_gcd(46, 240)
      {2, 47, -9}
      iex> Integer.extended_gcd(-46, 240)
      {2, -47, -9}
      iex> Integer.extended_gcd(-46, -240)
      {2, -47, 9}

      iex> Integer.extended_gcd(14, 21)
      {7, -1, 1}

      iex> Integer.extended_gcd(10, 0)
      {10, 1, 0}
      iex> Integer.extended_gcd(0, 10)
      {10, 0, 1}
      iex> Integer.extended_gcd(0, 0)
      {0, 0, 0}

  """
  @doc since: "1.12.0"
  @spec extended_gcd(integer, integer) :: {non_neg_integer, integer, integer}
  def extended_gcd(0, 0), do: {0, 0, 0}
  def extended_gcd(0, b), do: {b, 0, 1}
  def extended_gcd(a, 0), do: {a, 1, 0}

  def extended_gcd(integer1, integer2) when is_integer(integer1) and is_integer(integer2) do
    extended_gcd(integer2, integer1, 0, 1, 1, 0)
  end

  defp extended_gcd(r1, r0, s1, s0, t1, t0) do
    div = div(r0, r1)

    case r0 - div * r1 do
      0 when r1 > 0 -> {r1, s1, t1}
      0 when r1 < 0 -> {-r1, -s1, -t1}
      r2 -> extended_gcd(r2, r1, s0 - div * s1, s1, t0 - div * t1, t1)
    end
  end

  @doc false
  @deprecated "Use Integer.to_charlist/1 instead"
  def to_char_list(integer), do: Integer.to_charlist(integer)

  @doc false
  @deprecated "Use Integer.to_charlist/2 instead"
  def to_char_list(integer, base), do: Integer.to_charlist(integer, base)
end
