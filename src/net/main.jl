#!/usr/bin/env julia
using Revise
using RCall 
@rlibrary ineq
using sim

## Input parameters
params = Dict{Symbol,Any}(
    :N => 30,                        # number of agents
    :num_iter => 100,                # number of iterations the simulation runs
    :openness => 0,                  # 0 <=> openness <=> 1   (0: always choose from neighbor, 1: always choose from entire city)
    :max_starting_wealth => 100,     # each agent starts with wealth U~(0,max_starting_wealth)
    :salary_range => 10,             # each iteration, each agent receives/loses U~(-salary_range, salary_range) wealth
    :proto_threshold => 50,          # each agent in an encounter must have wealth about proto_threshold to form a proto
    :make_anim => false,             # do, or do not, create an animation of results
    :animation_delay => 20,          # milliseconds between animation frames
    :random_seed => 1234,            # random number generator starting seed
)

specnet(params)

