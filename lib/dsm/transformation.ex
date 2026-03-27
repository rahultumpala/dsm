defmodule Dsm.Transformation do
  def get_transformations_block(cur_state_name, state_options) do
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
end
