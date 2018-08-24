defmodule ParserTest do
  use ExUnit.Case
  doctest Parser

  describe "peeks at tokentype at specified index (default 0) in list; true or false" do
    test "first and second token" do
      assert Parser.peek(:num, [{:num, "2"}, {:var, "x"}]) == true
      assert Parser.peek(:num, [{:opar, "("}, {:var, "x"}]) == false
      assert Parser.peek(:var, [{:num, "2"}, {:var, "x"}], 1) == true
      assert Parser.peek(:num, [{:opar, "("}, {:var, "x"}], 1) == false
    end

    test "index error" do
      assert Parser.peek(:num, [{:num, "2"}, {:var, "x"}], 3) == nil
    end
  end

  # describe "idea for new output" do
  #   pending "just an idea" do
  #     Parser.level(Tokenizer.tokenize("2x")) == {
  #       type: :product,
  #       left: {
  #         type: :num,
  #         value: 2.0
  #       },
  #       right: {
  #         type: :var,
  #         name: "x"
  #       }
  #     }

  #     # [
  #     #   num: 2.0,
  #     #   times: "*",
  #     #   var: "x"
  #     # ]
  #   end
  # end

  describe "adds multiplication signs where they were not necessary" do
    test "simple cases" do
      assert Parser.add_times([{:num, "2"}, {:var, "x"}]) == [
               {:num, "2"},
               {:times, "*"},
               {:var, "x"}
             ]
    end

    test "everything..." do
      assert Parser.add_times(Tokenizer.tokenize("3x(2x+2)(x^2(2+x))*5*x")) == [
               num: 3.0,
               times: "*",
               var: "x",
               times: "*",
               opar: "(",
               num: 2.0,
               times: "*",
               var: "x",
               plus: "+",
               num: 2.0,
               cpar: ")",
               times: "*",
               opar: "(",
               var: "x",
               power: "^",
               num: 2.0,
               times: "*",
               opar: "(",
               num: 2.0,
               plus: "+",
               var: "x",
               cpar: ")",
               cpar: ")",
               times: "*",
               num: 5.0,
               times: "*",
               var: "x"
             ]
    end
  end
end
