
# Misc helper functions.

module Misc

# verbosity: 0=critical, 1=informational, 2=debug
# "pri": "print informational"
# "prd": "print debug"
export verbosity, pri, prd

verbosity = 1

function pri(x) 
    if verbosity > 0
        println(x)
    end
end

function prd(x) 
    if verbosity > 1
        println(x)
    end
end

end
