#!/usr/bin/env julia

using Gadfly
using LightGraphs
using GraphPlot, Compose
using Fontconfig    # must be using'd *after* Compose!
using Colors
using Misc

################################ functions ################################
in_proto(node) = any(node in proto for proto in protos)

eligible_for_proto(node) = wealths[node] > proto_threshold && !in_proto(node)

function form_proto(node1, node2)
    pr("Forming PI with $(node1) and $(node2)!")
    global protos
    push!(protos, Set{Int64}([node1,node2]))
end
###########################################################################


params = Dict(
    "N" => 20,
    "openness" => .1, 
    "num_iter" => 100,
    "max_starting_wealth" => 100,
    "proto_threshold" => 50
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
max_starting_wealth = params["max_starting_wealth"]
proto_threshold = params["proto_threshold"]


# A set of proto-institutions, each of which is a set of member vertex numbers.
protos = Set{Set{Int64}}()

# The initial social network.
graph = LightGraphs.SimpleGraphs.erdos_renyi(N,.2)

wealths = rand(Float16, N) * max_starting_wealth
colors = Color[]


# Erase old images.
run(`rm /tmp/output*.png`)

for iter in 1:num_iter
    pr("Iteration $(iter)...")
    node1 = rand(1:N)
    if rand(Float16) < openness  ||  length(neighbors(graph,node1)) == 0
        # Choose from the graph at large.
        node2 = rand(filter(x->x!=node1,1:N))
        pr("$(node1) encounters at-large $(node2)")
    else
        # Choose from a neighbor.
        node2 = rand(neighbors(graph,node1))
        pr("$(node1) encounters neighbor $(node2)")
    end
    if eligible_for_proto(node1) && eligible_for_proto(node2)
        form_proto(node1, node2)
    end

    colors = [ in_proto(n) ? colorant"red" : colorant"lightblue" for n in 1:N ]

    draw(PNG("/tmp/output$(iter).png"),
        gplot(graph, 
            nodelabel=1:N,
            NODESIZE=.08,
            nodefillc=colors))
end

run(`convert -delay 20 /tmp/output*.png /tmp/output.gif`)
