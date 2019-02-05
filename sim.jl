#!/usr/bin/env julia

using Gadfly
using LightGraphs
using GraphPlot, Compose
using Colors
using Misc


params = Dict(
    "N" => 20,
    "openness" => .1, 
    "num_iter" => 100
)

println("Running SriMilG...")
if length(ARGS) == 4
    using_defaults = false
    params["N"] = ARGS[1]
    params["openness"] = ARGS[2]
    params["num_iter"] = ARGS[3]
elseif length(ARGS) == 0
    using_defaults = true
else
    println("Usage: sim.jl N openness num_iter.")
end

println("Using" * (using_defaults ? " defaults" : "") * ":")
display(params)

# There must be a better way to do this using eval():
N = params["N"]
openness = params["openness"]
num_iter = params["num_iter"]



colors = rand((colorant"lightblue",colorant"red"), N)
wealths = rand(Float16, N)

graph = LightGraphs.SimpleGraphs.erdos_renyi(N,.2)
gplot(graph, 
    nodelabel=1:N,
    NODESIZE=.08,
    nodefillc=colors)

for iter in 1:num_iter
    pr("Iteration $(iter)...")
    node1 = rand(1:N)
    if rand(Float16) < openness
        # Choose from the graph at large.
        node2 = rand(filter(x->x!=node1,1:N))
        pr("$(node1), and at-large $(node2)")
    else
        # Choose from a neighbor.
        node2 = rand(neighbors(graph,node1))
        pr("$(node1), and neighbor $(node2)")
    end
end
