module sim
using RCall
@rlibrary ineq
using Gadfly
using LightGraphs
using GraphPlot, Compose
using ColorSchemes, Colors
using Misc
using Random
using Cairo, Fontconfig
using DataFrames

export specnet

function specnet(params)
    println("SPECnet simulation parameters:")
    for (param, val) in params
        println("   $(param) = $(val)")
        @eval $param=$val
    end

    global locs_x, locs_y

    LETTERS = collect('A':'Z')
    [ push!(LETTERS, x) for x in 'a':'z' ]

    Random.seed!(random_seed)

    # Note on representation:
    #
    # An "agent" is identified by a letter (see LETTERS variable, above.) An
    # agent's letter *always stays the same*, even when agents die.
    #
    # The word "node," on the other hand, refers to an integer in the range
    # 1:N_t, which is the current number of living agents at time t. The node
    # numbers will always occupy the entire contiguous sequence 1:N_t (with no
    # "holes").
    #
    # Example: suppose N_0 is 5, so there are 5 agents initially. At the start
    # of the sim, the agents are A, B, C, D, E, and the nodes are 1, 2, 3, 4,
    # 5. If agents B and D die, then the living agents would be A, C, E, and
    # the corresponding nodes would be 1, 2, 3.
    #
    # The global variable AN is an (always currently maintained) mapping from
    # agent numbers to node numbers. To find the graph node that corresponds to
    # a particular agent a, do this:
    #
    #     AN[a]
    #
    # To find the agent that corresponds to a particular node n, do this:
    #
    #     [ a for a in keys(AN) if AN[a] == n ][1]
    #
    # (Yes, this reverse lookup is not efficient. If this turns out to be a
    # problem, will implement two dictionaries, one in each direction, and keep
    # them ruthlessly in sync.)
    #
    ################################ functions ################################

    # Mark the agent "dead" whose agent number is passed. This involves
    # surgically removing it from the graph, adding it to the "dead" list,
    # adjusting the agent-to-node mappings, and deleting it from the list of
    # last-frame's plot coordinates.
    function kill_agent(dying_agent)
        global graph, dead, AN, locs_x, locs_y, wealths
        dying_node = AN[dying_agent]
        deleteat!(locs_x, dying_node)
        deleteat!(locs_y, dying_node)

        neighbor_nodes = neighbors(graph, dying_node)
        while length(neighbor_nodes) > 0
            rem_edge!(graph, dying_node, neighbor_nodes[1])
            neighbor_nodes = neighbors(graph, dying_node)
        end
        push!(dead, dying_agent)
        AN = Dict{Char,Any}(a=>
            (a==dying_agent ? Nothing :
                (AN[a] == nv(graph) ? AN[dying_agent] : AN[a]))
            for (a,n) in AN)
        # TODO: the rem_vertices!() function that Simon Schoelly wrote returns
        # a map of old-to-new node numbers, and might be safer.
        rem_vertex!(graph, dying_node)
        pop!(AN,dying_agent)
        pop!(wealths,dying_agent)
    end

    # Return true if the agent is a member of any proto institution.
    in_proto(agent) = any(agent in proto for proto in protos)

    # Return true if the agent is a rich enough to joing a proto, and available
    # to do so.
    function eligible_for_proto(agent)
        return wealths[agent] > proto_threshold && !in_proto(agent)
    end

    #return true if agent is wealthy enough to join proto
    function wealth_eligible(agent)
           return wealths[agent] > proto_threshold
    end

    # Form a new proto between two agents.
    function form_proto(agent1, agent2)
        global protos
        push!(protos, Set{Char}([agent1,agent2]))
    end

    # agent joins preexisting proto
    function join_proto(agent1,proto)
        push!(proto,agent1)
        for agent in proto
            if !has_edge(graph, AN[agent], AN[agent1])
                add_edge!(graph, AN[agent], AN[agent1])
            end
        end
    end
		
    #return the proto a given agent is in
    function get_proto(agent1)
        if(!in_proto(agent1))
            return -1
        else
            for proto in protos
                if agent1 in proto
                    return proto
                end
            end
        end
    end

    function assert_no_dead_neighbors(graph, agent, dead)
        node = AN[agent]
        if intersect(
            Set(map(node->[ a for a in keys(AN) if AN[a] == node ][1],
                neighbors(graph, node))), dead) != Set()
            nodes_to_agents = rev_dict(AN)
            error("Dead neighbor of $(agent)!\n" *
                "neighbors: $(nodes_to_agents[neighbors(graph, node)]) "*
                "dead: $(dead)")
        end
    end

    function compute_colors()
        global protos, possible_colors, N
        [ in_proto([ a for a in keys(AN) if AN[a] == node ][1]) ?
            possible_colors[
                findfirst(x->[ a for a in keys(AN) if AN[a] == node ][1] in x,
                                                                    protos)] :
                ([ a for a in keys(AN) if AN[a] == node ][1] in dead ?
                        colorant"pink" : colorant"lightgrey")
        for node in 1:nv(graph) ]
    end
   ginis=[]
    rev_dict(d) = Dict(y=>x for (x,y) in d)
    ###########################################################################


    println("Run SPECnet...")


    # A list of proto-institutions, each of which is a set of participating
    # agent numbers. (Could be a set instead of a list, but we're using it as
    # an index to the colors array, to uniquely color members of each proto.)
    global protos = Set{Char}[]
 
    # The numbers of agents who have perished (initially none).
    global dead = Set{Char}()

    # The initial social network.
    global graph = LightGraphs.SimpleGraphs.erdos_renyi(N,.2)
    while !is_connected(graph)
        global graph
        pri("Not connected; regenerating...")
        graph = LightGraphs.SimpleGraphs.erdos_renyi(N,.2)
    end
    global AN = Dict{Char,Any}(LETTERS[k]=>k for k in 1:N)

    # Agent attributes.
    global wealths =
        Dict{Char,Any}(LETTERS[k]=>
            rand(Float16) * max_starting_wealth for k in 1:N)

    global possible_colors = Random.shuffle(ColorSchemes.rainbow.colors)


    # (Erase old images.)
    rm("$(tempdir())/graph"*".png", force=true)
    rm("$(tempdir())/graph"*".svg", force=true)
    rm("$(tempdir())/wealth"*".png", force=true)
    rm("$(tempdir())/wealth"*".svg", force=true)
    rm("$(tempdir())/GiniPlot.png", force=true)
    locs_x, locs_y = nothing, nothing

    println("Iterations:")

    for iter in 1:num_iter

        nodes_to_agents = rev_dict(AN)

        if iter % 10 == 0 println(iter) else print(".") end

        global graph, locs_x, locs_y

        if locs_x == nothing
            locs_x, locs_y = spring_layout(graph)
        else
            locs_x, locs_y = spring_layout(graph, locs_x, locs_y)
        end

        agent1 = rand(keys(AN))
        assert_no_dead_neighbors(graph, agent1, dead)
        if rand(Float16) < openness  ||
                length(neighbors(graph, AN[agent1])) == 0
            # Choose from the graph at large.
            agent2 = rand(filter(x->x!=agent1,keys(AN)))
            prd("$(agent1) encounters at-large $(agent1)")
        else
            # Choose from a neighbor.
            node2 = rand(neighbors(graph,AN[agent1]))
            nodes_to_agents = rev_dict(AN)
            agent2 = nodes_to_agents[node2]
            prd("$(agent1) encounters neighbor $(agent2)")
        end
        assert_no_dead_neighbors(graph, agent2, dead)

        if eligible_for_proto(agent1) && eligible_for_proto(agent2)
            form_proto(agent1, agent2)
            # Since they're forming a proto, they also become socially
            # connected (if they weren't already.)
            if !has_edge(graph, AN[agent1], AN[agent2])
                add_edge!(graph, AN[agent1], AN[agent1])
            end
        end
                                                                                                #allow agent to join proto
	    if wealth_eligible(agent1) && wealth_eligible(agent2)
	        if in_proto(agent1)&&!in_proto(agent2)
	            current_proto=get_proto(agent1)
	            join_proto(agent2,current_proto)
	        end

            if in_proto(agent2)&&!in_proto(agent1)
	            current_proto=get_proto(agent2)
	            join_proto(agent1,current_proto)
	        end
	    end

        # Plot graph for this iteration.
        colors = compute_colors()

        remember_layout = x -> spring_layout(x, locs_x, locs_y)

        labels_to_plot = map(node->[ a for a in keys(AN) if AN[a] == node ][1],
            1:length(AN))
        wealths_to_plot = map(
            node->wealths[[ a for a in keys(AN) if AN[a] == node ][1]],
            1:length(AN))
        graphp = gplot(graph,
            layout=remember_layout,
            nodelabel=labels_to_plot,
            NODESIZE=.08,
            nodesize=ifelse.(wealths_to_plot .> 0,
                             wealths_to_plot*4,
                             maximum(wealths_to_plot)*2),
            nodestrokec=colorant"grey",
            nodestrokelw=.5,
            nodefillc=colors)
        draw(PNG("$(tempdir())/graph$(lpad(string(iter),3,'0')).png"),graphp)

        # Plot wealth histogram for this iteration.
        wealthp = plot(x=collect(values(wealths)),
            Geom.histogram(density=true, bincount=20),
            Guide.xlabel("Wealth"),
            Guide.ylabel("Density of agents"),
            Guide.title("Wealth distribution at iteration $(iter)"),
            # Hard to know what to set the max value to.
            Scale.x_continuous(minvalue=0,
                maxvalue=max_starting_wealth*num_iter/10),
            theme)

        draw(PNG("$(tempdir())/wealth$(lpad(string(iter),3,'0')).png"),wealthp)


        #iteration label for svg files
        if make_anim
            run(`mogrify -format svg -gravity South -pointsize 15 -annotate 0 "Iteration $(iter) of $(num_iter)"  $(joinpath(tempdir(),"graph"))$(lpad(string(iter),3,'0')).png`)
            run(`mogrify -format svg $(joinpath(tempdir(),"wealth"))$(lpad(string(iter),3,'0')).png`)
        end

        # Payday!
        [ wealths[k] += (rand(Float16) - .5) * salary_range
            for k in keys(wealths) ]
        [ wealths[k] += in_proto(k) ? rand(Float16)*10 : 0
            for k in keys(wealths) ]

        dying_agents =
            [ k for k in keys(wealths) if wealths[k] < 0 && !(k in dead) ]
        for dying_agent in dying_agents
            prd("Agent $(dying_agent) died!")
            kill_agent(dying_agent)
        end
    
        #adding current gini index to ginis array
        wealthArray=[]
        empty!(wealthArray)
        for k in keys(wealths)
            if wealths[k]>=-400
                push!(wealthArray,wealths[k])
            end
        end
        cGini=ineq(wealthArray, type="Gini")

        gIndex=convert(Float16,cGini)	   
        push!(ginis,gIndex)

    end   # End main simulation for loop

    # Collect results in DataFrame.
    results = DataFrame(
        agent = collect(keys(wealths)),
        wealth = collect(values(wealths))
    )

    #drawing the gini index plot
    giniPlot=plot(x=1:num_iter,y=ginis, Geom.point, Geom.line, Guide.xlabel("Iteration"), Guide.ylabel("Gini Index"))
    draw(PNG("$(tempdir())/GiniPlot.png"), giniPlot)
    
    if make_anim
        println("Building wealth animation (be unbelievably patient)...")
        run(`convert -delay $(animation_delay) $(joinpath(tempdir(),"wealth"))"*".svg $(joinpath(tempdir(),"wealth.gif"))`)
        println("Building graph animation (be mind-bogglingly patient)...")
        run(`convert -delay $(animation_delay) $(joinpath(tempdir(),"graph"))"*".svg $(joinpath(tempdir(),"graph.gif"))`)
    end

    println("...ending SPECnet.")
end

end

