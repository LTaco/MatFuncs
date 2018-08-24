defmodule Tokenizer do
  @token_list [
    [:num, "\\d+(\\.\\d+)?"],
    [:plus, "\\+"],
    [:minus, "-"],
    [:times, "\\*"],
    [:divide, "/"],
    [:power, "\\^"],
    [:var, "[x-z]"],
    [:opar, "\\("],
    [:cpar, "\\)"],
    [:space, "\\s+"],
    [:sin, "sin"],
    [:cos, "cos"],
    [:tan, "tan"],
    [:abs, "abs"],
    [:mod, "mod"],
    [:comma, ","]
  ]

  def tokenize(string) do
    tokens = []

    tokenize_one(string, tokens)
    |> token_editing
  end

  def tokenize_one("", tokens), do: tokens

  def tokenize_one(string, tokens) do
    pair =
      Enum.map(@token_list, fn [token_type, re] ->
        re = ~r/^#{re}/

        if Regex.match?(re, string) do
          matched_string = Regex.run(re, string) |> Enum.at(0)

          {token_type, matched_string}
        end
      end)
      |> Enum.reject(&is_nil/1)

    case pair do
      [{type, value}] ->
        tokens = List.insert_at(tokens, -1, {type, value})

        string
        |> String.replace_prefix(value, "")
        |> tokenize_one(tokens)

      _ ->
        IO.puts(:stderr, "Error while tokenizing here: #{string}")
    end
  end

  def token_editing(tokens) do
    tokens
    |> Enum.map(fn {type, value} ->
      case type do
        :num -> {type, Enum.at(Tuple.to_list(Float.parse(value)), 0)}

        :space -> {:space, " "}

        _ -> {type, value}
      end
    end)
  end



end
