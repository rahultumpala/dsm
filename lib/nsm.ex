defmodule Nsm do
  @moduledoc """
  Documentation for `Nsm`.
  """
  require Logger
  import Validator
  import Handler

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

    defined_states = defined_states |> Enum.map(&append_state_name_to_state_options/1)

    state_triggers = Enum.map(defined_states, &get_state_specific_trigger_block/1)

    nsm_context = %Nsm.Context{
      name: keyword_get(nsm_defintion, :name),
      state: keyword_get(nsm_defintion, :initial_state)
    }

    quote do
      def get_ssm_context() do
        unquote(nsm_context |> Macro.escape())
      end

      def trigger(context = %Nsm.Context{}, input) do
        response = trigger_with_state(context.state, input)

        case response do
          {:ok, output, new_state} ->
            {%Nsm.Context{context | state: new_state}, {:ok, output}}

          {:error, error, new_state} ->
            {%Nsm.Context{context | state: new_state}, {:error, error}}
        end
      end

      unquote_splicing(state_triggers)

      defp trigger_with_state(state, _) do
        raise ArgumentError,
          description: "State #{state} is not defined. Are you invoking this function manually?"
      end
    end
  end
end
