defmodule Dsm.MsgHandler do
  import Dsm.{Util, ErrorHandler}

  def get_handlers_block(cur_state_name, state_options) do
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
              |> Enum.reduce({:ok, input, unquote(cur_state_name)}, fn {matcher, executor,
                                                                        new_state},
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
end
