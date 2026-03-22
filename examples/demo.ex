defmodule Demo do
  use Nsm

  @thousand_island_options [
    port: 12001,
    thousand_island_options: [],
    thousand_island_terminal_callbacks: [
      close: FunctionRef,
      error: FunctionRef,
      shutdown: FunctionRef,
      timeout: FunctionRef
    ],
    buffer: <<>>
  ]

  nsm do
    [
      name: "demo-state-machine",
      context: [],
      default_transformations: [
        # All Function Refs are of the form &Module.Function/arity
        FunctionRef
      ],
      initial_state: :listen,
      initial_telemetry: FunctionRef
    ]
  end

  nsm_state :listen do
    [
      msg_unpacker_pipeline: [FunctionRef],
      any_match_msg_handlers: [
        {:term, match_criteria_1, FunctionRef},
        {:function, MatchCriteriaFunctionRef, FunctionRef}
      ],
      allowed_transitions: [:logged_in, :invalid_user],
      enter_telemetry: FunctionRef,
      # Exit telemetry gets additional data containing timestamps.
      exit_telemetry: FunctionRef
    ]
  end

  nsm_state :logged_in do
    [
      msg_unpacker_pipeline: [FunctionRef],
      msg_handler_pipeline: [
        {:term, %LoggedInUserStruct{}, FunctionRef},
        {:function, FunctionRef, FunctionRef},
        # 4th element of this tuple is the transition state.
        {:term, {:ok, _}, FunctionRef, :admin_authorized}
      ],
      error_handlers: [
        # All Matching Error Handlers are executed when there is an untrapped error.
        {:term, :error_type, FunctionRef},
        {:function, FunctionRef, FunctionRef}
      ],
      allowed_transitions: [:admin_authorized],
      enter_telemetry: FunctionRef,
      exit_telemetry: FunctionRef
    ]
  end

  nsm_state :invalid_user do
    [
      # Terminal states close connection
      terminal_state: true,
      enter_telemetry: FunctionRef,
      exit_telemetry: FunctionRef,
      cleanup_pipeline: [FunctionRef]
    ]
  end
end
