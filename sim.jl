#!/usr/bin/env julia

using Gadfly
using LightGraphs
using GraphPlot, Compose
using Colors

println("Running SriMilG...")
if length(ARGS) == 2
    defaults = false
    N = ARGS[1]
    openness = ARGS[2]
elseif length(ARGS) == 0
    defaults = true
    N = 20
    openness = .1
else
    println("Usage: sim.jl N openness.")
end

println("Using " * (defaults ? "defaults" : "") *
    " (N=$(N), openness=$(openness))...")

graph = LightGraphs.SimpleGraphs.erdos_renyi(N,.2)
gplot(graph, 
    nodelabel=1:N,
    NODESIZE=.08,
    nodefillc=colorant"red")
