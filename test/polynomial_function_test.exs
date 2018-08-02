defmodule PolynomialFunctionTest do
  use ExUnit.Case
  doctest PolynomialFunction

  describe "cleans up user input string" do
    test "trims whitespace from start and end" do
      assert PolynomialFunction.clean_up_string(" 1    ") == "1"
      assert PolynomialFunction.clean_up_string(" 2x    ") == "2x"
    end

    test "removes whitespace between digits and operands" do
      assert PolynomialFunction.clean_up_string("1 + 1") == "1+1"
      # TODO: is this valid input? Or not?
      assert PolynomialFunction.clean_up_string("2 3") == "23"
      assert PolynomialFunction.clean_up_string("2       3") == "23"
    end

    test "replaces python power syntax with math power syntax" do
      # TODO: what to do if there is no `x` here, but a number instead?
      assert PolynomialFunction.clean_up_string("x**3") == "x^3"
      assert PolynomialFunction.clean_up_string("2x**4") == "2x^4"
    end

    test "converts German floats to floats" do
      assert PolynomialFunction.clean_up_string("1,2") == "1.2"
    end

    test "replaces a `-` with `+-`" do
      assert PolynomialFunction.clean_up_string("1-2+3") == "1+-2+3"
    end

    test "removes a single `*`" do
      assert PolynomialFunction.clean_up_string("1+2*x") == "1+2x"
    end
  end

  describe "converts polynomials to tuples" do
    test "extracts exponent and factor" do
      assert PolynomialFunction.polynomial_to_tuple("3x^2") == {2.0, 3.0}
    end

    test "can deal with floats" do
      assert PolynomialFunction.polynomial_to_tuple("4.5x^3") == {3.0, 4.5}
    end

    test "takes an x without factor for a 1" do
      assert PolynomialFunction.polynomial_to_tuple("x^2") == {2.0, 1.0}
    end

    test "deals with negative numbers" do
      assert PolynomialFunction.polynomial_to_tuple("-2x^2") == {2.0, -2.0}
      assert PolynomialFunction.polynomial_to_tuple("2x^-2") == {-2.0, 2.0}
      assert PolynomialFunction.polynomial_to_tuple("-2x^-2") == {-2.0, -2.0}
      assert PolynomialFunction.polynomial_to_tuple("-x^2") == {2.0, -1.0}
    end

    test "allows a missing exponent" do
      assert PolynomialFunction.polynomial_to_tuple("2x") == {1.0, 2.0}
    end

    test "allows a missing variable" do
      assert PolynomialFunction.polynomial_to_tuple("2") == {0.0, 2.0}
    end
  end

  describe "simplifies polynomial tuples" do
    test "leaves sorted and simple polynomials as is" do
      assert PolynomialFunction.simplify([{2.0, 2.0}, {1.0, 1.0}]) == [{2.0, 2.0}, {1.0, 1.0}]
    end

    test "combines like exponents" do
      assert PolynomialFunction.simplify([{2.0, 2.0}, {2.0, 1.0}, {1.0, 1.0}]) == [
               {2.0, 3.0},
               {1.0, 1.0}
             ]
    end

    test "reorders result from high to low" do
      assert PolynomialFunction.simplify([{2.0, 2.0}, {3.0, 2.0}, {2.0, 1.0}, {1.0, 1.0}]) == [
               {3.0, 2.0},
               {2.0, 3.0},
               {1.0, 1.0}
             ]
    end

    test "removes zero values" do
      assert PolynomialFunction.simplify([{2.0, 2.0}, {2.0, -2.0}, {1.0, 1.0}]) == [{1.0, 1.0}]
      assert PolynomialFunction.simplify([{2.0, 2.0}, {2.0, -2.0}]) == []
    end

    test "does nothing if given empty list" do
      assert PolynomialFunction.simplify([]) == []
    end
  end

  describe "creates a function string from polynomial tuples" do
    test "single standard polynomial" do
      assert PolynomialFunction.func_to_string([{3.0, 2.0}]) == "2x^3"
      assert PolynomialFunction.func_to_string([{2.0, 4.0}]) == "4x^2"
    end

    test "multiple standard polynomials" do
      assert PolynomialFunction.func_to_string([{3.0, 2.0}, {2.0, 2.0}]) == "2x^3+2x^2"
    end

    test "floats" do
      assert PolynomialFunction.func_to_string([{3.2, 2.5}, {2.123, 2.0}]) == "2.5x^3.2+2x^2.123"
    end

    test "negative polynomials" do
      assert PolynomialFunction.func_to_string([{3.0, -2.0}]) == "-2x^3"
      assert PolynomialFunction.func_to_string([{3.0, -2.0}, {2.0, -2.0}]) == "-2x^3-2x^2"
      assert PolynomialFunction.func_to_string([{3.0, -2.0}, {2.0, 2.0}]) == "-2x^3+2x^2"
      assert PolynomialFunction.func_to_string([{3.0, 2.0}, {2.0, -2.0}]) == "2x^3-2x^2"
    end

    test "polynomials without exponent" do
      assert PolynomialFunction.func_to_string([{1.0, -2.0}]) == "-2x"
      assert PolynomialFunction.func_to_string([{3.0, 2.0}, {1.0, 2.0}]) == "2x^3+2x"
    end

    test "factors without x" do
      assert PolynomialFunction.func_to_string([{0.0, 2.0}]) == "2"
      assert PolynomialFunction.func_to_string([{0.0, -13.0}]) == "-13"
      assert PolynomialFunction.func_to_string([{3.0, 2.0}, {0.0, 2.0}]) == "2x^3+2"
    end
  end
end
