defmodule Example.Validations do
  def valid_read_output?(data) do
    case data do
      {:ok, bytes} -> {:ok, bytes}
      _ -> {:error, "invalid read output"}
    end
  end

  def valid_intermediate_output?(data) do
    case data do
      {_fmt = %{}, _other_data} -> {:ok, data}
      _ -> {:error, "invalid intermediate output"}
    end
  end
end
