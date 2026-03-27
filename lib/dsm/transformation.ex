defmodule Dsm.Transformation do
  import Dsm.Util

  def get_transformations_block(cur_state_name, state_options) do
    tfs = Keyword.get(state_options, :transformations, [])
    telemetry_fn = get_telemetry_fn(state_options)

    quote do
      def execute_transformations(state, input) when state == unquote(cur_state_name) do
        tfs_result =
          unquote(tfs |> Macro.escape())
          |> Enum.reduce(:__tf_not_started, fn tf_function, acc ->
            tf_start_time = System.monotonic_time(:nanosecond)

            # Actual Execution
            output =
              if acc == :__tf_not_started do
                # this is the first function in the Transformations pipeline so this must be executed with the user input
                # the output of this function will act as the input of the next function.
                tf_function.(input)
              else
                # this is NOT the first function in the Transformations pipeline
                # It can be executed with the output of the previous transformation function
                tf_function.(acc)
              end

            # Telemetry code
            tf_end_time = System.monotonic_time(:nanosecond)

            invoke_telemetry_fn(
              unquote(telemetry_fn),
              tf_function,
              state,
              {:ok, tf_end_time - tf_start_time}
            )

            # return actual output
            output
          end)
      end
    end
  end
end
