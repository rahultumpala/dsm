defmodule Handler do
  import Validator

  def get_state_specific_trigger_block({cur_state_name, state_options}) do
    handler_block = get_handlers_block(cur_state_name, state_options)
    tfs_block = get_transformations_block(cur_state_name, state_options)

    quote do
      unquote(handler_block)
      unquote(tfs_block)

      defp trigger_with_state(current_state, input)
           when current_state == unquote(cur_state_name) do
        output = execute_transformations(current_state, input)
        execute_handlers(current_state, output)
      end
    end
  end

  defp get_handlers_block(cur_state_name, state_options) do
    handlers = get_handlers(state_options)

    case handlers do
      # Must match all
      # a variable input is expected to be present in the context of the code block
      {:all, pipeline} ->
        error_handlers = get_error_handlers(state_options)

        quote do
          def execute_handlers(state, input) when state == unquote(cur_state_name) do
            handler_result =
              unquote(pipeline |> Macro.escape())
              |> Enum.reduce({:ok, input, unquote(cur_state_name)}, fn {matcher, executor, new_state},
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

                    _ ->
                      raise ArgumentError, description: "Invalid output from a handler/matcher."
                  end

                acc
              end)

            case handler_result do
              {:error, error} ->
                error_handler_result =
                  unquote(error_handlers |> Macro.escape())
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

                  nil ->
                    # if code reached here then no error handlers were even defined, it was an empty list.
                    {:error, error, unquote(cur_state_name)}
                end

              {:ok, response, new_state} ->
                # No error in the msg handler pipeline so return the actual output.
                {:ok, response, new_state}
            end
          end
        end

      {:any, pipeline} ->
        # can run on any match
        # a variable input is expected to be present in the context of the code block
        quote bind_quoted: [pipeline: pipeline |> Macro.escape(), state_name: cur_state_name] do
          def execute_handlers(state, input) when state == cur_state_name do
            handler_result =
              pipeline
              |> Enum.reduce(nil, fn {matcher, executor, new_state}, acc ->
                acc =
                  case matcher.(input) do
                    {:ok, matcher_output} ->
                      {:ok, executor.(matcher_output), new_state}

                    {:error, error} ->
                      # just return the error along with the new state which is the current state itself
                      {:error, error, cur_state_name}
                  end
              end)
          end
        end
    end
  end

  defp get_transformations_block(cur_state_name, state_options) do
    tfs = Keyword.get(state_options, :transformations, [])

    quote bind_quoted: [tfs: tfs |> Macro.escape(), state: cur_state_name] do
      def execute_transformations(state, input) when state == state do
        tfs_result =
          unquote(tfs |> Macro.escape())
          |> Enum.reduce(:__tf_not_started, fn tf_function, acc ->
            if acc == :__tf_not_started do
              # this is the first function in the Transformations pipeline so this must be executed with the user input
              # the output of this function will act as the input of the next function.
              tf_function.(input)
            else
              # this is NOT the first function in the Transformations pipeline
              # It can be executed with the output of the previous transformation function
              tf_function.(acc)
            end
          end)
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
