defmodule Tree do
  @operations_op_a [:sin, :cos, :tan, :abs]
  @tree_to_string_keywords %{
    plus: "+",
    minus: "-",
    times: "*",
    divide: "/",
    power: "^",
    sin: "sin",
    cos: "cos",
    tan: "tan"
  }

  # def transform([head | []]) do
  # if Parser.peek(:num, head) do
  #   Simplifier.get_value(head)
  # else
  # Simplifier.get_value(head)
  # |> String.to_atom()
  # end
  # end

  def transform(tokens, count \\ 0) do
    if Parser.peek(:cpar, tokens, count + 2) do
      if Parser.peek(:num, tokens, count + 1) do
        Simplifier.get_value(tokens, count + 1)
      else
        Simplifier.get_value(tokens, count + 1)
        |> String.to_atom()
      end
    else
      [op, left, right] =
        if Parser.get_type(tokens, count + 1) in @operations_op_a do
          left =
            if Parser.peek(:opar, tokens, count + 2) do
              transform(tokens, count + 2)
            else
              if Parser.peek(:num, tokens, count + 2) do
                Simplifier.get_value(tokens, count + 2)
              else
                Simplifier.get_value(tokens, count + 2)
                |> String.to_atom()
              end
            end

          op = Parser.get_type(tokens, count + 1)

          right = nil
          [op, left, right]
        else
          left =
            if Parser.peek(:opar, tokens, count + 1) do
              transform(tokens, count + 1)
            else
              if Parser.peek(:num, tokens, count + 1) do
                Simplifier.get_value(tokens, count + 1)
              else
                Simplifier.get_value(tokens, count + 1)
                |> String.to_atom()
              end
            end

          op =
            if Parser.peek(:opar, tokens, count + 1) do
              Parser.go_past_par(tokens, count + 1, count + 1)
            else
              Parser.get_type(tokens, count + 2)
            end

          at =
            if Parser.peek(:opar, tokens, count + 1) do
              Parser.go_past_par(tokens, count + 1, count + 1, 0, [:count, nil]) + 1
            else
              count + 3
            end

          right =
            if Parser.peek(:opar, tokens, at) do
              transform(tokens, at)
            else
              if Parser.peek(:num, tokens, at) do
                Simplifier.get_value(tokens, at)
              else
                Simplifier.get_value(tokens, at)
                |> String.to_atom()
              end
            end

          [op, left, right]
        end

      [op, [left, right]]
    end
  end

  def tree_to_string(float) when is_float(float) do
    if float == Float.floor(float) do
      Float.to_string(float)
      |> String.replace(".0", "")
    else
      Float.to_string(float)
    end
  end

  def tree_to_string(atom) when is_atom(atom) do
    Atom.to_string(atom)
  end

  def tree_to_string([op | [[left | [nil]]]]) do
    left = tree_to_string(left)
    operator = Map.get(@tree_to_string_keywords, op)
    # "(#{operator}#{left})"
    "#{operator}#{left}"
  end

  def tree_to_string([op | [[left | right]]]) do
    [right | _] = right
    left = tree_to_string(left)
    operator = Map.get(@tree_to_string_keywords, op)
    right = tree_to_string(right)
    #"(#{left}#{operator}#{right})"
    "#{left}#{operator}#{right}"
  end
end
