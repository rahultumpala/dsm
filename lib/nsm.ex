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

  @doc """
    Perform the following validations:
    - Check if the shape of pipelines are valid
    - Check if all declared states have a valid nsm_state definition
    - Check if the state transitions are valid
    - Check if the given Function Refs are valid and can be resolved
    - Check if both msg_handler_pipeline and any_match_handler are given
  """
  defmacro before_compile(env) do
    nsm_defintion = Module.get_attribute(env.module, :__nsm_def__) |> dbg

    nsm_defintion |> validate_nsm_options!()

    defined_states = Module.get_attribute(env.module, :__nsm_state__) |> dbg

    defined_states
    |> validate_all_states_are_present!(nsm_defintion)
    |> Enum.each(&validate_nsm_state!(&1, nsm_defintion))
  end
end
