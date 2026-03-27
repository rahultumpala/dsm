defmodule Dsm.ErrorHandler do
  import Dsm.{Util}

  def get_error_handlers(state_options) do
    state_options
    |> Keyword.get(:error_handlers, [])
    |> Enum.map(&normalize_handler_entries(&1, state_options))
  end
end
