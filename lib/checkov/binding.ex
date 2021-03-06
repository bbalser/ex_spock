defmodule Checkov.Binding do
  def get_bindings({:where, _, [[{key, data} | _tail] = keywords]}) when is_atom(key) do
    0..(Enum.count(data) - 1)
    |> Enum.map(fn index -> create_binding(keywords, index) end)
  end

  def get_bindings({:where, _, [[variables | data]]}) do
    Enum.map(data, fn list -> Enum.zip(variables, list) end)
  end

  defp create_binding(keywords, index) do
    keywords
    |> Enum.map(fn {key, value} -> {key, to_enumerable(value)} end)
    |> Enum.map(fn {key, values} -> {key, Enum.at(values, index)} end)
  end

  def valid?({:where, _, [[{key, _data} | _tail] = keywords]}) when is_atom(key) do
    Keyword.values(keywords) |> all_same_count?()
  end

  def valid?({:where, _, [list]}) do
    all_same_count?(list)
  end

  defp all_same_count?(list) do
    uniq_counts =
      list
      |> Enum.map(fn value -> to_enumerable(value) end)
      |> Enum.map(fn sublist -> Enum.count(sublist) end)
      |> Enum.uniq()
      |> Enum.count()

    uniq_counts <= 1
  end

  defp to_enumerable(x) do
    case Enumerable.impl_for(x) do
      nil -> Code.eval_quoted(x) |> elem(0)
      _ -> x
    end
  end
end
