# nsm

*nsm* stands for Networking as State Machines.

*nsm* models TCP interactions as declarative Finite State Machines, where handlers are defined per event and composed through pattern matching and pipelines.

*nsm* structures message handling, error propagation, rollback logic, and event extraction into consistent pipelines, replacing ad-hoc networking code with a clear, state-driven architecture for building scalable and maintainable network applications.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `nsm` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:nsm, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/nsm>.

