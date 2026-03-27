defmodule Dsm.Util do
  def normalize_handler_entries(entry, state_options) do
    current_state_name = Keyword.get(state_options, :name)

    case entry do
      # Set new state as the current state name if new state is not explicitly defined.
      {matcher, executor} -> {matcher, executor, current_state_name}
      {matcher, executor, new_state} -> {matcher, executor, new_state}
    end
  end

  def get_handlers(state_options) do
    handler_pipeline = keyword_get(state_options, :msg_handler_pipeline)
    any_match_handler = keyword_get(state_options, :any_match_msg_handlers)

    if handler_pipeline == nil do
      any_match_handler =
        any_match_handler |> Enum.map(&normalize_handler_entries(&1, state_options))

      {:any, any_match_handler}
    else
      handler_pipeline =
        handler_pipeline |> Enum.map(&normalize_handler_entries(&1, state_options))

      {:all, handler_pipeline}
    end
  end

  def keyword_get(list, key) do
    Keyword.get(list, key, nil)
  end

  def get_telemetry_fn(state_options) do
    keyword_get(state_options, :telemetry)
  end

  def invoke_telemetry_fn(telemetry_fn, executing_fn, state_name, data) do
    with true <- telemetry_fn != nil,
         info <- Function.info(executing_fn),
         module <- Keyword.get(info, :module),
         name <- Keyword.get(info, :name),
         arity <- Keyword.get(info, :arity) do
      telemetry_fn.({state_name, module, name, arity}, data)
    end
  end
end
