defmodule Parser do
  @operands [:plus, :minus, :times, :divide, :power, nil]
  @operations_op_a [:sin, :cos, :tan, :abs]
  @operations_op_a_b [:mod]

  def init(tokens) do
    tokens
    |> level

    # |> parse
  end

  @spec level(any()) :: any()
  def level(tokens) do
    tokens =
      tokens
      |> negative_num_at_start()
      #|> IO.inspect(label: "1")
      |> put_brackets_around_expression_args
      #|> IO.inspect(label: "2")
      |> put_brackets_around_expression
      #|> IO.inspect(label: "3")
      |> add_times
      #|> IO.inspect(label: "4")
      |> put_brackets_around_operation_types([:power])
      #|> IO.inspect(label: "5")
      |> put_brackets_around_operation_types([:times, :divide])
      #|> IO.inspect(label: "6")
      |> put_brackets_around_operation_types([:plus, :minus])
      #|> IO.inspect(label: "7")
      |> put_brackets_around_everything()
      #|> IO.inspect(label: "8")
      |> remove_double_pars()
      #|> IO.inspect(label: "9")

    tokens
  end

  def negative_num_at_start(tokens, count \\ 0) do
    if Enum.at(tokens, count) != nil do
      if peek(:minus, tokens, count) && peek(:num, tokens, count + 1) &&
           (count == 0 || peek(:opar, tokens, count - 1)) do
        {{_, _}, tokens} = List.pop_at(tokens, count)
        value = Simplifier.get_value(tokens, count)

        tokens
        |> List.replace_at(count, {:num, value * -1})
        |> negative_num_at_start(count + 1)
      else
        tokens
        |> negative_num_at_start(count + 1)
      end
    else
      tokens
    end
  end

  def put_brackets_around_expression_args(tokens, count \\ 0) do
    if Enum.at(tokens, count) != nil do
      type = get_type(tokens, count)

      tokens =
        cond do
          type in @operations_op_a ->
            put_brackets_around_expression_args_op_a(tokens, count)

          type in @operations_op_a_b ->
            put_brackets_around_expression_args_op_a_b(tokens, count)

          true ->
            tokens
        end

      tokens
      |> put_brackets_around_expression_args(count + 1)
    else
      tokens
    end
  end

  def put_brackets_around_expression_args_op_a(tokens, count \\ 0, par_count \\ 0) do
    tokens = remove_type(tokens, :space, count + 1)

    tokens =
      if get_type(tokens, count) in @operands do
        if par_count > 0 do
          tokens
          |> List.insert_at(count, {:cpar, ")"})
          |> put_brackets_around_expression_args_op_a(count, par_count - 1)
        else
          tokens
        end
      else
        if (peek(:num, tokens, count - 1) || peek(:var, tokens, count - 1)) &&
             get_type(tokens, count) in @operations_op_a && par_count > 0 do
          tokens
          |> List.insert_at(count, {:cpar, ")"})
          |> put_brackets_around_expression_args_op_a(count, par_count - 1)
        else
          put_brackets_around_expression_args_op_a(tokens, count + 1, par_count)
        end
      end

    tokens =
      if get_type(tokens, count) in @operations_op_a && peek(:opar, tokens, count + 1, true) do
        tokens
        |> List.insert_at(count + 1, {:opar, "("})
        |> put_brackets_around_expression_args_op_a(count + 2, par_count + 1)
      else
        tokens
      end

    tokens
  end

  def put_brackets_around_expression_args_op_a_b(tokens, count \\ 0) do
    tokens = remove_type(tokens, :space, count + 1)

    tokens =
      if Enum.at(tokens, count) != nil do
        if peek(:comma, tokens, count) do
          tokens
          |> List.insert_at(go_past_par(tokens, count, count, 1, [:count, nil]), {:cpar, ")"})
          |> List.insert_at(count + 1, {:opar, "("})
          |> List.insert_at(count, {:cpar, ")"})
          |> List.insert_at(
            go_past_par(tokens, count + 1, count + 1, 1, [:count, nil], true) + 1,
            {:opar, "("}
          )
        else
          tokens
          |> put_brackets_around_expression_args_op_a_b(count + 1)
        end
      else
        tokens
      end

    tokens
  end

  def put_brackets_around_expression(tokens, count \\ 0) do
    if Enum.at(tokens, count) != nil do
      if get_type(tokens, count) in (@operations_op_a ++ @operations_op_a_b) &&
           peek(:opar, tokens, count - 1, true) do
        temp = go_past_par(tokens, count + 1, count + 1, 0, [:count, nil])

        tokens
        |> List.insert_at(temp, {:cpar, ")"})
        |> List.insert_at(count, {:opar, "("})
        |> put_brackets_around_expression(count + 2)
      else
        tokens
        |> put_brackets_around_expression(count + 1)
      end
    else
      tokens
    end
  end

  def put_brackets_around_operation_types(tokens, types, count \\ 0) do
    if Enum.at(tokens, count) != nil do
      if get_type(tokens, count) in types do
        unless peek(:opar, tokens, count - 2) && peek(:cpar, tokens, count + 2) do
          tokens
          |> put_brackets_around_operation_types_right(count)
          |> put_brackets_around_operation_types_left(count)
          |> put_brackets_around_operation_types(types, count + 3)
        else
          tokens
          |> put_brackets_around_operation_types(types, count + 1)
        end
      else
        tokens
        |> put_brackets_around_operation_types(types, count + 1)
      end
    else
      tokens
    end
  end

  defp put_brackets_around_operation_types_right(tokens, count) do
    type = get_type(tokens, count + 1)

    cond do
      type == :num || type == :var ->
        List.insert_at(tokens, count + 2, {:cpar, ")"})

      type == :opar ->
        at = go_past_par(tokens, count + 1, count + 1, 0, [:count, nil])
        List.insert_at(tokens, at, {:cpar, ")"})

      true ->
        raise("Error in put_brackets_around_operation_types_right()")
    end
  end

  defp put_brackets_around_operation_types_left(tokens, count) do
    type = get_type(tokens, count - 1)

    cond do
      type == :num || type == :var ->
        List.insert_at(tokens, count - 1, {:opar, "("})

      type == :cpar ->
        at = go_past_par(tokens, count - 1, count - 1, 0, [:count, nil], true)
        List.insert_at(tokens, at + 1, {:opar, "("})

      true ->
        raise("Error in put_brackets_around_operation_types_left()")
    end
  end

  def add_times(tokens, count \\ 0) do
    if Enum.at(tokens, count) != nil do
      case get_type(tokens, count) do
        :num ->
          if peek(:opar, tokens, count + 1) || peek(:var, tokens, count + 1),
            do: tokens |> List.insert_at(count + 1, {:times, "*"}) |> add_times(count + 2),
            else: tokens |> add_times(count + 1)

        :var ->
          if peek(:opar, tokens, count + 1) || peek(:var, tokens, count + 1),
            do: tokens |> List.insert_at(count + 1, {:times, "*"}) |> add_times(count + 2),
            else: tokens |> add_times(count + 1)

        :cpar ->
          if peek(:opar, tokens, count + 1),
            do: tokens |> List.insert_at(count + 1, {:times, "*"}) |> add_times(count + 2),
            else: tokens |> add_times(count + 1)

        _ ->
          tokens |> add_times(count + 1)
      end
    else
      tokens
    end
  end

  def put_brackets_around_everything(tokens) do
    unless peek(:opar, tokens) do
      tokens
      |> List.insert_at(0, {:opar, "("})
      |> List.insert_at(-1, {:cpar, ")"})
    else
      tokens
    end
  end

  def remove_double_pars(tokens, count \\ 0) do
    if Enum.at(tokens, count + 1) != nil do
      if go_past_par(tokens, count , count, 0, [:count, nil]) - go_past_par(tokens, count + 1, count + 1, 0, [:count, nil]) ==
          1 do
        {_, tokens} = List.pop_at(tokens, go_past_par(tokens, count + 1 , count + 1, 0, [:count, nil]))
        {_, tokens} = List.pop_at(tokens, count + 1)
        remove_double_pars(tokens, count)
      else
        tokens
        |> remove_double_pars(count + 1)
      end
    else tokens
    end
  end

  def peek(type, tokens, index \\ 0, negate? \\ false) do
    if Enum.at(tokens, index) != nil do
      if negate? do
        type !=
          Enum.at(tokens, index)
          |> Tuple.to_list()
          |> Enum.at(0)
      else
        type ==
          Enum.at(tokens, index)
          |> Tuple.to_list()
          |> Enum.at(0)
      end
    else
      nil
    end
  end

  def get_type(tokens, index \\ 0) do
    if Enum.at(tokens, index) != nil do
      Enum.at(tokens, index)
      |> Tuple.to_list()
      |> Enum.at(0)
    else
      nil
    end
  end

  def consume(key, [{key, val} | tail]) do
    {{key, val}, tail}
  end

  def consume(expected_type, [{key, _} | _]) do
    IO.puts(:stderr, "Error while parsing: expected #{expected_type} but got #{key}")
  end

  def remove_type(tokens, type, count \\ 0) do
    if peek(type, tokens, count) do
      {_, tokens} = List.pop_at(tokens, count)
      tokens
    else
      tokens
    end
  end

  # count should be equal to start, operation [:get_type, nil] ,[:peek, :type] or [:count, nil]
  # for starting at the beginning of a (...): par_cnt = 0;
  # in the middle of it: par_count > 0 for the number of leading parentheies skipped
  def go_past_par(
        tokens,
        count \\ 0,
        start \\ 0,
        par_cnt \\ 0,
        operation \\ [:get_type, nil],
        backwards? \\ false
      ) do
    if backwards? do
      if count != start do
        if par_cnt == 0 do
          case Enum.at(operation, 0) do
            :count -> if count < 0, do: 0, else: count
            :peek -> peek(Enum.at(operation, 1), tokens, count)
            :get_type -> get_type(tokens, count)
          end
        else
          if peek(:cpar, tokens, count) || peek(:opar, tokens, count) do
            if peek(:cpar, tokens, count) do
              go_past_par(tokens, count - 1, start, par_cnt + 1, operation, true)
            else
              go_past_par(tokens, count - 1, start, par_cnt - 1, operation, true)
            end
          else
            go_past_par(tokens, count - 1, start, par_cnt, operation, true)
          end
        end
      else
        if peek(:cpar, tokens, count) || par_cnt != 0 do
          if par_cnt != 0 do
            go_past_par(tokens, count - 1, start, par_cnt, operation, true)
          else
            go_past_par(tokens, count - 1, start, par_cnt + 1, operation, true)
          end
        else
          case Enum.at(operation, 0) do
            :count -> if count < 0, do: 0, else: count
            :peek -> peek(Enum.at(operation, 1), tokens, count)
            :get_type -> get_type(tokens, count)
          end
        end
      end
    else
      if count != start do
        if par_cnt == 0 do
          case Enum.at(operation, 0) do
            :count -> count
            :peek -> peek(Enum.at(operation, 1), tokens, count)
            :get_type -> get_type(tokens, count)
          end
        else
          if peek(:opar, tokens, count) || peek(:cpar, tokens, count) do
            if peek(:opar, tokens, count) do
              go_past_par(tokens, count + 1, start, par_cnt + 1, operation)
            else
              go_past_par(tokens, count + 1, start, par_cnt - 1, operation)
            end
          else
            go_past_par(tokens, count + 1, start, par_cnt, operation)
          end
        end
      else
        if peek(:opar, tokens, count) || par_cnt != 0 do
          if par_cnt != 0 do
            go_past_par(tokens, count + 1, start, par_cnt, operation)
          else
            go_past_par(tokens, count + 1, start, par_cnt + 1, operation)
          end
        else
          case Enum.at(operation, 0) do
            :count -> count
            :peek -> peek(Enum.at(operation, 1), tokens, count)
            :get_type -> get_type(tokens, count)
          end
        end
      end
    end
  end
end
