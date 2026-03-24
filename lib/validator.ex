defmodule Validator do
  @moduledoc """
    Perform the following validations:
    - Check if the shape of pipelines are valid
    - Check if all declared states have a valid nsm_state definition
    - Check if the state transitions are valid
    - Check if the given Function Refs are valid and can be resolved
    - Check if both msg_handler_pipeline and any_match_handler are given
  """

  @valid_state_options MapSet.new([
                         :transformations,
                         :any_match_msg_handlers,
                         :msg_handler_pipeline,
                         :error_handlers,
                         :telemetry
                       ])

  @valid_nsm_options MapSet.new([
                       :name,
                       :context,
                       :initial_state,
                       :all_states
                     ])

  def validate_nsm_options!(nsm_options) do
    validations = [
      {keyword_get(nsm_options, :name) == nil,
       fn ->
         raise CompileError,
           description: "Expected :name for the nsm but could not find the option."
       end},
      {keyword_get(nsm_options, :initial_state) == nil,
       fn ->
         raise CompileError,
           description: "Expected :initial_state for the nsm but could not find the option."
       end},
      {keyword_get(nsm_options, :all_states) == nil,
       fn ->
         raise CompileError,
           description: "Expected :all_states for the nsm but could not find the option."
       end}
    ]

    validations
    |> Enum.each(fn {condition, error} ->
      if condition do
        error.()
      end
    end)

    ensure_has_recognized_options_only!(nsm_options, @valid_nsm_options)

    ensure_option_values_are_lists!(nsm_options, [:all_states])
  end

  def validate_all_states_are_present!(defined_states, nsm_options) do
    all_states = keyword_get(nsm_options, :all_states) |> MapSet.new()

    defined_states
    |> Enum.each(fn {name, _} ->
      case MapSet.member?(all_states, name) do
        false ->
          raise CompileError,
            description:
              "A state :#{name} has been defined but not included in the :all_states option of nsm definition."

        true ->
          # ignore
          nil
      end
    end)

    defined_states
  end

  def validate_nsm_state!({state_name, state_options}, nsm_def) do
    all_states = keyword_get(nsm_def, :all_states)
    handler_pipeline = keyword_get(state_options, :msg_handler_pipeline)
    any_match_handler = keyword_get(state_options, :any_match_msg_handlers)

    validations = [
      {handler_pipeline == nil && any_match_handler == nil,
       fn ->
         raise CompileError,
           description:
             "Either of :msg_handler_pipeline or :any_match_msg_handlers must be defined but state :#{state_name} defines none."
       end},
      {handler_pipeline != nil && any_match_handler != nil,
       fn ->
         raise CompileError,
           description:
             "Either of :msg_handler_pipeline or :any_match_msg_handlers must be defined but state :#{state_name} defines both."
       end}
    ]

    validations
    |> Enum.each(fn {condition, error} ->
      if condition do
        error.()
      end
    end)

    ensure_has_recognized_options_only!(state_options, @valid_state_options)

    ensure_option_values_are_lists!(state_options, [
      :transformations,
      :any_match_msg_handlers,
      :msg_handler_pipeline,
      :error_handlers
    ])

    handler_entries =
      if handler_pipeline != nil do
        handler_pipeline
      else
        any_match_handler
      end

    handler_entries =
      if keyword_get(state_options, :error_handlers) != nil do
        handler_entries ++ keyword_get(state_options, :error_handlers)
      else
        handler_entries
      end

    if keyword_get(state_options, :transformations) != nil do
      tfs = keyword_get(state_options, :transformations)
      tfs |> Enum.each(&ensure_function_ref!/1)
    end

    handler_entries |> Enum.each(&validate_pipeline_entry!(&1, all_states))
  end

  def validate_pipeline_entry!(entry, all_states) do
    case entry do
      {match_ref, exec_ref} ->
        ensure_function_ref!(exec_ref)
        ensure_function_ref!(match_ref)

      {match_ref, exec_ref, new_state} ->
        ensure_function_ref!(exec_ref)
        ensure_function_ref!(match_ref)
        ensure_new_state_in_all_states!(new_state, all_states)

      _ ->
        raise CompileError, description: "The provided entry #{entry} is of unknown shape."
    end
  end

  def ensure_function_ref!(ref) do
    try do
      info = Function.info(ref)

      arity = keyword_get(info, :arity)
      name = keyword_get(info, :name)

      if arity != 1 do
        raise CompileError,
          description:
            "Received a function #{name} with arity #{arity}. Expected a function with arity of 1."
      end
    rescue
      ArgumentError -> raise CompileError, description: "Expected a function but received #{ref}"
    end
  end

  def ensure_new_state_in_all_states!(new_state, all_states) do
    if keyword_get(all_states, new_state) == nil do
      raise CompileError,
        description: "The state #{new_state} is not defined in :all_states of the nsm definition."
    end
  end

  def keyword_get(list, key) do
    Keyword.get(list, key, nil)
  end

  def ensure_has_recognized_options_only!(options, recognized_options) do
    options
    |> Enum.each(fn {name, _} ->
      if !MapSet.member?(recognized_options, name) do
        raise CompileError,
          description: "The option :#{name} is not recognized."
      end
    end)
  end

  def ensure_option_values_are_lists!(options, keys) do
    keys
    |> Enum.each(fn key ->
      val = keyword_get(options, key)

      if val != nil && !is_list(val) do
        raise CompileError, description: "Expected a List structure for option :#{key}."
      end
    end)
  end
end
