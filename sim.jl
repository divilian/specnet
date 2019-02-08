#!/usr/bin/env julia

using Gadfly
using LightGraphs
using GraphPlot, Compose
using ColorSchemes, Colors
using Misc
using Random

################################ functions ################################
in_proto(node) = any(node in proto for proto in protos)

eligible_for_proto(node) = wealths[node] > proto_threshold && !in_proto(node)

function form_proto(node1, node2)
    prd("Forming PI with $(node1) and $(node2)!")
    global protos
    push!(protos, Set{Int64}([node1,node2]))
end

function compute_colors()
    global protos, possible_colors
    [ in_proto(n) ?
        possible_colors[findfirst(x -> n in x, protos)] :
        (n in dead ? colorant"black" : colorant"lightgrey") for n in 1:N ]
end

function remove_node(node)
    # See warnings at http://juliagraphs.github.io/LightGraphs.jl/latest/generators.html#LightGraphs.SimpleGraphs.rem_vertex!
    # Let's just sever the node from its neighbors and put it in an isolated 
    # place. Otherwise, not only do we have to adjust all the external data 
    # structures (wealths, colors, etc.) but the node numbers will suddenly 
    # change making things difficult to track.
    global graph, dead
    friends = collect(neighbors(graph, node))
    for friend in friends
        prd("Removing edge between $(node) and $(friend)...")
        rem_edge!(graph, node, friend)
    end
    push!(dead, node)
end
###########################################################################


params = Dict(
    "N" => 20,
    "openness" => .2,
    "num_iter" => 100,
    "max_starting_wealth" => 100,
    "mean_salary" => 10,
    "proto_threshold" => 50
)

println("Running SriMilG...")
if length(ARGS) == 6
    using_defaults = false
    params["N"] = ARGS[1]
    params["openness"] = ARGS[2]
    params["num_iter"] = ARGS[3]
    params["max_starting_wealth"] = ARGS[4]
    params["mean_salary"] = ARGS[5]
    params["proto_threshold"] = ARGS[6]
elseif length(ARGS) == 0
    using_defaults = true
else
    println("Usage: sim.jl N openness num_iter max_starting_wealth mean_salary proto_threshold.")
end

println("Using" * (using_defaults ? " defaults" : "") * ":")
display(params)

# There must be a better way to do this using eval():
N = params["N"]
openness = params["openness"]
num_iter = params["num_iter"]
max_starting_wealth = params["max_starting_wealth"]
mean_salary = params["mean_salary"]
proto_threshold = params["proto_threshold"]


# A list of proto-institutions, each of which is a set of member vertex
# numbers. (Could be a set, but we're using it as an index to the colors
# array, to uniquely color members of each proto.)
protos = Set{Int64}[]

# The nodes that have perished (initially none).
dead = Set{Int64}()

# The initial social network.
graph = LightGraphs.SimpleGraphs.erdos_renyi(N,.2)
while !is_connected(graph)
    pri("Not connected; regenerating...")
    graph = LightGraphs.SimpleGraphs.erdos_renyi(N,.2)
end

wealths = rand(Float16, N) * max_starting_wealth
possible_colors = Random.shuffle(ColorSchemes.rainbow.colors)


# Erase old images.
run(`rm -f /tmp/output*.svg`)

locs_x, locs_y = nothing, nothing

for iter in 1:num_iter

    pri("Iteration $(iter)...")

    global locs_x, locs_y

    if locs_x == nothing
        locs_x, locs_y = spring_layout(graph)
    else
        locs_x, locs_y = spring_layout(graph, locs_x, locs_y)
    end

    node1 = rand(1:N)
    if rand(Float16) < openness  ||  length(neighbors(graph,node1)) == 0
        # Choose from the graph at large.
        node2 = rand(filter(x->x!=node1,1:N))
        prd("$(node1) encounters at-large $(node2)")
    else
        # Choose from a neighbor.
        node2 = rand(neighbors(graph,node1))
        prd("$(node1) encounters neighbor $(node2)")
    end
    if eligible_for_proto(node1) && eligible_for_proto(node2)
        form_proto(node1, node2)
        # Since they're forming a proto, they also become socially connected
        # (if they weren't already.)
        if !has_edge(graph, node1, node2)
            add_edge!(graph, node1, node2)
        end
    end

    colors = compute_colors()

    remember_layout = x -> spring_layout(x, locs_x, locs_y)

    plot = gplot(graph,
        layout=remember_layout,
        nodelabel=1:N,
        NODESIZE=.08,
        nodesize=wealths*4,
        nodestrokec=colorant"grey",
        nodestrokelw=.5,
        nodefillc=colors)
    draw(SVG("/tmp/output$(lpad(string(iter),3,'0')).svg"), plot)

    # Payday!
    wealths .+= (rand(Float16, N) .- .5) .* mean_salary
    proto_payoffs = [ in_proto(n) ? rand(Float16)*10 : 0 for n in 1:N ]
    wealths .+= proto_payoffs

    dying_nodes = setdiff((1:N)[wealths .< 0], dead)
    for dying_node in dying_nodes
        pri("Agent $(dying_node) died!")
        remove_node(dying_node)
    end
end

run(`convert -delay 20 /tmp/output*.svg /tmp/output.gif`)
