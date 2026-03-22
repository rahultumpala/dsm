defmodule Nsm do
  @moduledoc """
  Documentation for `Nsm`.
  """
  require Logger

  defmacro __using__() do
    # Generate start_link
  end

  defmacro nsm(do: block) do
    quote do
      opts = unquote(block)

      validations = [
        {keyword_get(opts, :name) != nil,
         &raise(CompileError,
           description: "Expected name for the nsm but could not find the option."
         )},
        {keyword_get(opts, :initial_state) != nil,
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

      case keyword_get(opts, :entrypoint) do
        {:thousand_island, options} ->
          nil
          # TODO: generate start_link here.
      end


    end
  end

  defp keyword_get(list, key) do
    Keyword.get(list, key, nil)
  end

  @doc """
  Hello world.

  ## Examples

      iex> Nsm.hello()
      :world

  """
  def hello do
    :world
  end
end
