defmodule Example.Demo do
  import Example.WaveFormat
  import Example.Validations
  use Dsm

  dsm do
    [
      name: "wav-file-reader-state-machine",
      initial_state: :ready,
      all_states: [:ready]
    ]
  end

  dsm_state :ready do
    [
      transformations: [&read_file_to_bytes/1],
      msg_handler_pipeline: [
        {&valid_read_output?/1, &read_riff_chunk/1},
        {&valid_intermediate_output?/1, &read_fmt_subChunk/1},
        {&valid_intermediate_output?/1, &read_data_subChunk/1}
      ],
      error_handlers: [],
      telemetry: &__MODULE__.telemetry/2
    ]
  end

  def telemetry({state, m, f, a}, data) do
    IO.inspect({"Telemetry Data for state :#{state} -- #{m}.#{f}/#{a}", data})
  end
end
