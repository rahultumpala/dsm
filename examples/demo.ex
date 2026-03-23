defmodule Demo do
  use Nsm

  nsm do
    [
      name: "demo-state-machine",
      context: [],
      initial_state: :listen,
      all_states: [:listen, :logged_in, :invalid_user]
    ]
  end

  nsm_state :listen do
    [
      transformations: [FunctionRef],
      any_match_msg_handlers: [
        {:term, MatchCriteria1, FunctionRef},
        {:function, MatchCriteriaFunctionRef, FunctionRef}
      ],
      telemetry: FunctionRef
    ]
  end

  nsm_state :logged_in do
    [
      transformations: [FunctionRef],
      msg_handler_pipeline: [
        {:term, %{}, FunctionRef},
        {:function, FunctionRef, FunctionRef},
        # 4th element of this tuple is the transition state.
        {:function, &({:ok, _} = &1), FunctionRef, :admin_authorized}
      ],
      error_handlers: [
        # All Matching Error Handlers are executed when there is an untrapped error.
        {:term, :error_type, FunctionRef},
        {:function, FunctionRef, FunctionRef}
      ],
      telemetry: FunctionRef
    ]
  end

  nsm_state :invalid_user do
    [
      msg_handler_pipeline: [],
      telemetry: FunctionRef
    ]
  end
end
