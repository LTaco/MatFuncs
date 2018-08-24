defmodule Simplifier do
  # s@operands [:plus, :minus, :times, :divide, :power]

  def simplify([a]) do
    a
  end

  def simplify([op, [a, b]]) when is_float(a) and is_float(b) do
    case op do
      :plus ->
        a + b

      :minus ->
        a - b

      :times ->
        a * b

      :divide ->
        unless b == 0, do: a / b, else: raise("Cannot divide by 0.")

      :power ->
        unless a == 0 && b == 0,
          do: :math.pow(a, b),
          else: raise("0 to the power of 0 is undefined.")
    end
  end

  def simplify([:power, [a, 0.0]]) when is_atom(a) do
    1.0
  end

  def simplify([:times, [a, 0.0]]) when is_atom(a) do
    0.0
  end

  def simplify([:times, [0.0, b]]) when is_atom(b) do
    0.0
  end

  def simplify([op, [a, b]]) when is_atom(a) and is_float(b) do
    [op, [a, b]]
  end

  def simplify([op, [a, b]]) when is_float(a) and is_atom(b) do
    [op, [a, b]]
  end

  def simplify([op, [a, b]]) when is_atom(a) and is_atom(b) do
    [op, [a, b]]
  end

  def simplify([op, [a, b]]) when is_float(a) and is_list(b) do
    if [op, [a, simplify(b)]] != [op, [a, b]] do
      simplify([op, [a, simplify(b)]])
    else
      [op, [a, b]]
    end
  end

  def simplify([op, [a, b]]) when is_list(a) and is_float(b) do
    if [op, [simplify(a), b]] != [op, [a, b]] do
      simplify([op, [simplify(a), b]])
    else
      [op, [a, b]]
    end
  end

  def simplify([op, [a, b]]) when is_list(a) and is_list(b) do
    if [op, [simplify(a), simplify(b)]] != [op, [a, b]] do
      simplify([op, [simplify(a), simplify(b)]])
    else
      [op, [a, b]]
    end
  end

  def simplify([op, [a, b]]) when is_atom(a) do
    [op, [a, simplify(b)]]
  end

  def simplify([op, [a, b]]) when is_atom(b) do
    [op, [simplify(a), b]]
  end

  def simplify([op, [a, b]]) do
    [op, [a, b]]
  end

  def get_value(tokens, count \\ 0) do
    if Enum.at(tokens, count) != nil do
      Enum.at(tokens, count)
      |> Tuple.to_list()
      |> Enum.at(1)
    else
      nil
    end
  end
end
