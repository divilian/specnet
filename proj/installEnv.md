
# Install Julia environment for SPECnet

## Ubuntu Linux

1. Download https://julialang-s3.julialang.org/bin/linux/x64/1.1/julia-1.1.0-linux-x86_64.tar.gz
2. Unpack (using "`tar xzvf julia-1.1.0-linux-x86_64.tar.gz`")
3. Add the `julia` executable to your `PATH`.
4. Start `julia`, hit the "`]`" key to enter package mode, then type:
```
    add Gadfly LightGraphs GraphPlot Compose ColorSchemes Colors Random
```
5. Create the directory `~/.julia/config` and the file `~/.julia/config/startup.jl` (if either doesn't already exist) and put this line in it:
```
   push!(LOAD_PATH, "/the/path/to/where/the/specnet/.jl/files/live")
```

Now, if you `cd` to `/the/path/to/where/the/specnet/.jl/files/live`, you can
either:
* Start the `julia` REPL and type `include("sim.jl")`, or
* Type `./sim.jl` at the command line.


