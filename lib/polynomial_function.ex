defmodule PolynomialFunction do
  def get_func_in_io() do
    raw_function = IO.gets("Function: ")
    make_function_usable(raw_function)
  end

  def make_function_usable(raw_function) do
    raw_function
    |> clean_up_string()
    |> String.split("+")
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&polynomial_to_tuple/1)
    |> simplify()
    #|> get_derivative()
    |> func_to_string()
  end

  def clean_up_string(str) do
    str
    |> String.replace(~r/\s/, "")
    |> String.replace("**", "^")
    |> String.replace(",", ".")
    |> String.replace("-", "+-")
    |> String.replace("*", "")
  end

  def polynomial_to_tuple(polynomial) do
    case String.split(polynomial, "x^") do
      [a] ->
        case Float.parse(a) do
          {val, ""} ->
            {0.0, val}

          {val, "x"} ->
            {1.0, val}

          _ ->
            case a do
              "x" ->
                {1.0, 1.0}

              "-x" ->
                {1.0, -1.0}
            end
        end

      [a, b] ->
        case a do
          "" ->
            {exp, _} = Float.parse(b)
            {exp, 1.0}

          "-" ->
            {exp, _} = Float.parse(b)
            {exp, -1.0}

          _ ->
            {val, _} = Float.parse(a)
            {exp, _} = Float.parse(b)
            {exp, val}
        end
    end
  end

  def simplify(polynomials) do
    polynomials
    |> Enum.group_by(fn {exp, _} -> exp end, fn {_, vl} -> vl end)
    |> Enum.map(fn {a, list} -> {a, Enum.reduce(list, fn n, acc -> n + acc end)} end)
    |> Enum.reject(fn {_, val} -> val == 0 end)
    |> Enum.reverse()
  end

  def get_derivative(list) do
    list
    |> Enum.map(fn {exp, val} ->
      case {exp, val} do
        {0.0, _} ->
          {0.0, 0.0}

        {_, _} ->
          val = val * exp
          exp = exp - 1
          {exp, val}
      end
    end)

    |> Enum.reject(&(&1 == {0.0, 0.0}))
  end

  def func_to_string(func) do
    func
    |> Enum.map(fn {exp, val} ->
      exp =
        cond do
          exp == Kernel.trunc(exp) ->
            Kernel.trunc(exp)
            |> Integer.to_string()

          true ->
            Float.to_string(exp)
        end

      val =
        cond do
          val == Kernel.trunc(val) ->
            Kernel.trunc(val)
            |> Integer.to_string()

          true ->
            Float.to_string(val)
        end

      case {val, exp} do
        {_, "0"} -> val
        {"1", "1"} -> "x"
        {"-1", "1"} -> "-x"
        {_, "1"} -> "#{val}x"
        {"1", _} -> "x^#{exp}"
        {"-1", _} -> "-x^#{exp}"
        {_, _} -> "#{val}x^#{exp}"
      end
    end)
    |> Enum.join("+")
    |> String.replace("+-", "-")
  end
end
