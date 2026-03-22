defmodule Nsm do
  @moduledoc """
  Documentation for `Nsm`.
  """
  require Logger

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
  """
  defmacro before_compile(env) do
    nsm_defintion = Module.get_attribute(env.module, :__nsm_def__) |> dbg
    defined_states = Module.get_attribute(env.module, :__nsm_state__) |> dbg
  end

  defp keyword_get(list, key) do
    Keyword.get(list, key, nil)
  end

  def validate_nsm_options(nsm_options) do
    validations = [
      {keyword_get(nsm_options, :name) != nil,
       fn ->
         raise CompileError,
           description: "Expected name for the nsm but could not find the option."
       end},
      {keyword_get(nsm_options, :initial_state) != nil,
       fn ->
         raise CompileError,
           description: "Expected initial state for the nsm but could not find the option."
       end}
    ]

    validations
    |> Enum.each(fn {condition, error} ->
      if !condition do
        error.()
      end
    end)
  end
end
