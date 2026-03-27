# Example

The following code snippet defines a valid DSM.

```elixir
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
```

Running the above snippet produces the following Telemetry events, and returns a 2 element Tuple containing the dsm context and the return value of the state.

```elixir
iex(1)> Example.Demo.get_ssm_context() |> Example.Demo.trigger("example/sample.wav")
{"Telemetry Data for state :ready -- Elixir.Example.WaveFormat.read_file_to_bytes/1",
 {:ok, 293416}}
{"Telemetry Data for state :ready -- Elixir.Example.Validations.valid_read_output?/1",
 {:ok, 709}}
{"Telemetry Data for state :ready -- Elixir.Example.WaveFormat.read_riff_chunk/1",
 {:ok, 2458}}
{"Telemetry Data for state :ready -- Elixir.Example.Validations.valid_intermediate_output?/1",
 {:ok, 542}}
{"Telemetry Data for state :ready -- Elixir.Example.WaveFormat.read_fmt_subChunk/1",
 {:ok, 3000}}
{"Telemetry Data for state :ready -- Elixir.Example.Validations.valid_intermediate_output?/1",
 {:ok, 417}}
{"Telemetry Data for state :ready -- Elixir.Example.WaveFormat.read_data_subChunk/1",
 {:ok, 2084}}
{%Dsm.Context{state: :ready, name: "wav-file-reader-state-machine"},
 {:ok,
  {%{
     "AudioFormat" => "PCM",
     "BitsPerSample" => 16,
     "BlockAlign" => 2,
     "ByteRate" => 8000,
     "ChunkID" => "RIFF",
     "ChunkSize" => 19468,
     "Format" => "WAVE",
     "NumChannels" => 1,
     "SampleRate" => 4000,
     "SubChunk1ID" => "fmt ",
     "SubChunk1Size" => 16,
     "SubChunk2ID" => "data",
     "SubChunk2Size" => 19432
   },
   <<0, 0, 131, 23, 154, 250, 90, 246, 183, 0, 222, 249, 236, 12, 157, 11, 113,
     232, 28, 250, 35, 20, 79, 255, 60, 252, 3, 254, 30, 243, 216, 12, 159, 17,
     171, 235, 233, 245, 68, 14, 49, 1, 73, 3, ...>>}}}
```