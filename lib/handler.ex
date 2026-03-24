defmodule Handler do
  import Validator

  def get_state_specific_trigger_block({state_name, state_options}) do
    handlers = get_handlers(state_options)

    fn_definition_block =
      case handlers do
        {:all, pipeline} ->
          # Must match all
          # a variable input is expected to be present in the context of the code block
          quote bind_quoted: [pipeline: pipeline |> Macro.escape()] do
            pipeline
            |> Enum.reduce({:ok, Macro.var(:input, nil), nil}, fn {matcher, executor, new_state},
                                                                  acc ->
              acc =
                case acc do
                  {:ok, prev_output, new_state} ->
                    case matcher.(prev_output) do
                      {:ok, matcher_output} ->
                        {:ok, executor.(matcher_output), new_state}

                      {:error, error} ->
                        {:error, error}
                    end

                  {:error, error} ->
                    {:error, error}
                end

              acc
            end)
          end

        {:any, pipeline} ->
          # can run on any match
          # a variable input is expected to be present in the context of the code block
          quote bind_quoted: [pipeline: pipeline |> Macro.escape(), state_name: state_name] do
            pipeline
            |> Enum.reduce(nil, fn {matcher, executor, new_state}, acc ->
              acc =
                case matcher.(Macro.var(:input, nil)) do
                  {:ok, matcher_output} ->
                    {:ok, executor.(matcher_output), new_state}

                  {:error, error} ->
                    # just return the error
                    {:error, error}
                end
            end)
          end
      end

    # quote bind_quoted: [fn_definition_block: fn_definition_block, state_name: state_name] do
    quote do
      def trigger_with_state(current_state, input)
          when current_state == unquote(state_name) do
        unquote(fn_definition_block)
      end
    end
  end

  defp get_handlers(state_options) do
    handler_pipeline = keyword_get(state_options, :msg_handler_pipeline)
    any_match_handler = keyword_get(state_options, :any_match_msg_handlers)

    if handler_pipeline == nil do
      any_match_handler = any_match_handler |> Enum.map(&normalize_handler_entries/1)
      {:any, any_match_handler}
    else
      handler_pipeline = handler_pipeline |> Enum.map(&normalize_handler_entries/1)
      {:all, handler_pipeline}
    end
  end

  def normalize_handler_entries(entry) do
    case entry do
      {matcher, executor} -> {matcher, executor, nil}
      {matcher, executor, new_state} -> {matcher, executor, new_state}
    end
  end
end
