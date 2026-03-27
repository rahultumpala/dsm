defmodule Dsm.Trigger do
  import Dsm.{Transformation, MsgHandler}

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
end
