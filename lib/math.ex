defmodule Math do
  def func(string) do
    string
    |> Tokenizer.tokenize()
    #|> IO.inspect
    |> Parser.level()
    #|> IO.inspect
    |> Tree.transform()
    |> IO.inspect
    |> Simplifier.simplify()
    |> IO.inspect
    |> Tree.tree_to_string()
  end
end
