defmodule Handler do
  import Validator

  def get_state_specific_trigger_block({cur_state_name, state_options}) do
    handlers = get_handlers(state_options)

    fn_definition_block =
      case handlers do
        # Must match all
        # a variable input is expected to be present in the context of the code block
        {:all, pipeline} ->
          error_handlers = get_error_handlers(state_options)

          quote bind_quoted: [
                  pipeline: pipeline |> Macro.escape(),
                  error_handlers: error_handlers |> Macro.escape()
                ] do
            handler_result =
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

                    # If any of the previous handlers in the pipeline failed then propagate their error
                    # without executing any subsequent handlers
                    {:error, error} ->
                      {:error, error}
                  end

                acc
              end)

            case handler_result do
              {:error, error} ->
                error_handler_result =
                  error_handlers
                  |> Enum.reduce(nil, fn {matcher, executor, new_state}, acc ->
                    if matcher.(handler_result) do
                      {:handler_matched, executor.(handler_result), new_state}
                    else
                      case acc do
                        # if any of the previous handlers matched then return their response
                        {:handler_matched, _, _} -> acc
                        # else return the original error result itself
                        _ -> handler_result
                      end
                    end
                  end)

                case error_handler_result do
                  # unwrap the error handler output and return it.
                  {:handler_matched, error_handler_output, new_state} ->
                    {error_handler_output, new_state}

                  # if code reached here then no error handlers could handle the error so return the error itself.
                  {:error, error, new_state} ->
                    {:error, error, new_state}
                end

              {:ok, response, new_state} ->
                # No error in the msg handler pipeline so return the actual output.
                {:ok, response, new_state}
            end
          end

        {:any, pipeline} ->
          # can run on any match
          # a variable input is expected to be present in the context of the code block
          quote bind_quoted: [pipeline: pipeline |> Macro.escape(), state_name: cur_state_name] do
            handler_result =
              pipeline
              |> Enum.reduce(nil, fn {matcher, executor, new_state}, acc ->
                acc =
                  case matcher.(Macro.var(:input, nil)) do
                    {:ok, matcher_output} ->
                      {:ok, executor.(matcher_output), new_state}

                    {:error, error} ->
                      # just return the error along with the new state which is the current state itself
                      {:error, error, cur_state_name}
                  end
              end)
          end
      end

    quote do
      def trigger_with_state(current_state, input)
          when current_state == unquote(cur_state_name) do
        unquote(fn_definition_block)
      end
    end
  end

  defp get_handlers(state_options) do
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

  defp get_error_handlers(state_options) do
    state_options
    |> Keyword.get(:error_handlers, [])
    |> Enum.map(&normalize_handler_entries(&1, state_options))
  end

  def normalize_handler_entries(entry, state_options) do
    current_state_name = Keyword.get(state_options, :name)

    case entry do
      # Set new state as the current state name if new state is not explicitly defined.
      {matcher, executor} -> {matcher, executor, current_state_name}
      {matcher, executor, new_state} -> {matcher, executor, new_state}
    end
  end
end
