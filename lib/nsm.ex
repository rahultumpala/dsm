defmodule Nsm do
  @moduledoc """
  Documentation for `Nsm`.
  """
  require Logger

  defmacro __using__(_) do
    quote do
      # Store the defined states.
      Module.register_attribute(__MODULE__, :__nsm_states__, accumulate: true)

      @before_compile {unquote(__MODULE__), :before_compile}
    end
  end

  defmacro nsm(do: block) do
    quote bind_quoted: [options: block] do
      defp keyword_get(list, key) do
        Keyword.get(list, key, nil)
      end

      def validate_nsm_options() do
        validations = [
          {keyword_get(options, :name) != nil,
           &raise(CompileError,
             description: "Expected name for the nsm but could not find the option."
           )},
          {keyword_get(options, :initial_state) != nil,
           &raise(CompileError,
             description: "Expected initial state for the nsm but could not find the option."
           )}
        ]

        validations
        |> Enum.each(fn {condition, error} ->
          if !condition do
            error.()
          end
        end)
      end

      def nsm_context() do
        options
      end

      def trigger(ctx) do
      end
    end
  end

  defmacro nsm_state(state_name, do: block) do
    quote bind_quoted: [options: block, state_name: state_name] do
      @__nsm_state__ state_name

      def get_state_ctx(name) when name == state_name do
        options
      end
    end
  end
end
