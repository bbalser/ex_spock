defmodule Checkov do

  defmacro __using__(_opts) do
    quote do
      import Checkov
      use ExUnit.Case
    end
  end

  defmacro data_test(name, context \\ quote(do: %{}), do: do_block) do
    {test_block, where} = Macro.prewalk(do_block, {}, fn exp, acc ->
      case match?({:where, _, _}, exp) do
        true -> {nil, exp}
        false -> {exp, acc}
      end
    end)

    bindings = get_bindings(where)

    Enum.map(bindings, fn binding ->
      unrolled_name(name, binding)
      |> create_test(binding, test_block, context)
    end)
  end

  defp unrolled_name(name, binding) do
    name_block = Macro.postwalk(name, fn exp ->
      case is_binding_variable?(exp, binding) do
        true -> {:var!, [context: Elixir, import: Kernel], [exp]}
        false -> exp
      end
    end)

    {unrolled_name, _ } = Code.eval_quoted(name_block, binding)
    unrolled_name
  end

  defp is_binding_variable?({atom, _, nil}, binding) do
    Keyword.has_key?(binding, atom)
  end
  defp is_binding_variable?(_exp, _binding), do: false

  defp create_test(name, binding, test_block, context) do
    quoted_variables = Enum.map(binding, fn { variable_name, variable_value} ->
      {:=, [], [{:var!, [context: Elixir, import: Kernel], [{variable_name, [], Elixir}]}, variable_value]}
    end)

    quote do
      test unquote(name), unquote(context) do
        unquote_splicing(quoted_variables)
        unquote(test_block)
      end
    end
  end

  defp get_bindings({:where, _, [[{key,data}|_tail] = keywords]}) when is_atom(key) do
    0..(Enum.count(data)-1)
    |> Enum.map(fn index -> create_binding(keywords, index) end)
  end
  defp get_bindings({:where, _ , [[variables|data]]}) do
    Enum.map(data, fn list -> Enum.zip(variables, list) end)
  end

  defp create_binding(keywords, index) do
    Keyword.keys(keywords)
    |> Enum.map(fn key ->
      { key, Keyword.get(keywords, key) |> Enum.at(index) }
    end)
  end

end