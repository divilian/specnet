
# Install Julia environment for SPECnet

## Ubuntu Linux

### Single machine

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

### Server

1. Download and install Jupyter Notebooks (`sudo apt-get install jupyter`).
1. Generate a config file: `jupyter-notebook --generate-config`. This makes a
   `~/.jupyter/jupyter_notebook_config.py` file.
    1. Generate a password by starting IPython, `from notebook.auth import passwd`, and `passwd()`. Type your password twice, and paste the result at the end of the `c.NotebookApp.password` line (which you must uncomment), and make sure there's a `u` before the first tick mark. (_e.g._, `c.NotebookApp.password = u'shat1:blahblahblahb'`)
    1. Change the `c.NotebookApp.port` line to have your desired port.
    1. Change the `c.NotebookApp.ip` line to have a splat in ticks: `'*'`
1. Add the `IJulia` package using the Julia package manager.
1. Start the server with `jupyter notebook --no-browser`.

