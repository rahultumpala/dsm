defmodule Nsm do
  @moduledoc """
  Documentation for `Nsm`.
  """
  require Logger
  import Validator

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)

      # Store the nsm definition
      Module.register_attribute(__MODULE__, :__nsm_state__, accumulate: true)

      # Store the defined states.
      Module.register_attribute(__MODULE__, :__nsm_state__, accumulate: true)

      @before_compile {unquote(__MODULE__), :before_compile}
    end
  end

  defmacro nsm(do: block) do
    quote do
      @__nsm_def__ unquote(block)
    end
  end

  defmacro nsm_state(state_name, do: block) do
    quote bind_quoted: [options: block, name: state_name] do
      @__nsm_state__ {name, options}
    end
  end

  defmacro before_compile(env) do
    nsm_defintion = Module.get_attribute(env.module, :__nsm_def__) |> dbg

    nsm_defintion |> validate_nsm_options!()

    defined_states = Module.get_attribute(env.module, :__nsm_state__) |> dbg

    defined_states
    |> validate_all_states_are_present!(nsm_defintion)
    |> Enum.each(&validate_nsm_state!(&1, nsm_defintion))

    state_triggers = Enum.map(defined_states, &get_state_specific_trigger_block/1)

    quote do
      defp perform_match(type, expected, actual) do
        case type do
          :term -> expected == actual
          :function -> expected.(actual) == true
        end
      end

      def trigger(context) do
        current_state = context.state

        updated_context = trigger_with_state(current_state, context)

        updated_context
      end

      unquote_splicing(state_triggers)
    end
  end

  defp get_state_specific_trigger_block({state_name, state_options}) do
    quote bind_quoted: [name: state_name] do
      def trigger_with_state(current_state, context) when current_state == name do
        # TODO: unquote quoted with blocks for each handler.
      end
    end
  end
end
