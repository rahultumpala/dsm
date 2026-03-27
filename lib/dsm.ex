defmodule Dsm do
  @moduledoc """
  Documentation for `Dsm`.
  """
  require Logger
  import Dsm.{Trigger, Validator, Util}

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)

      # Store the dsm definition
      Module.register_attribute(__MODULE__, :__dsm_state__, accumulate: true)

      # Store the defined states.
      Module.register_attribute(__MODULE__, :__dsm_state__, accumulate: true)

      @before_compile {unquote(__MODULE__), :before_compile}
    end
  end

  defmacro dsm(do: block) do
    quote do
      @__dsm_def__ unquote(block)
    end
  end

  defmacro dsm_state(state_name, do: block) do
    quote bind_quoted: [options: block, name: state_name] do
      @__dsm_state__ {name, options}
    end
  end

  defmacro before_compile(env) do
    dsm_defintion = Module.get_attribute(env.module, :__dsm_def__) |> dbg

    dsm_defintion |> validate_dsm_options!()

    defined_states = Module.get_attribute(env.module, :__dsm_state__) |> dbg

    defined_states
    |> validate_all_states_are_present!(dsm_defintion)
    |> Enum.each(&validate_dsm_state!(&1, dsm_defintion))

    defined_states = defined_states |> Enum.map(&append_state_name_to_state_options/1)

    state_triggers = Enum.map(defined_states, &get_state_specific_trigger_block/1)

    dsm_context = %Dsm.Context{
      name: keyword_get(dsm_defintion, :name),
      state: keyword_get(dsm_defintion, :initial_state)
    }

    quote do
      def get_ssm_context() do
        unquote(dsm_context |> Macro.escape())
      end

      def trigger(context = %Dsm.Context{}, input) do

        all_states = keyword_get(unquote(dsm_defintion), :all_states) |> MapSet.new()

        if !MapSet.member?(all_states, context.state) do
            raise ArgumentError,
              message: "The state #{context.state} is not recognized in this DSM."
        end

        response = trigger_with_state(context.state, input)

        case response do
          {:ok, output, new_state} ->
            {%Dsm.Context{context | state: new_state}, {:ok, output}}

          {:error, error, new_state} ->
            {%Dsm.Context{context | state: new_state}, {:error, error}}
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
