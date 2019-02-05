
module Misc

export pr, verbosity

verbosity = 1

function pr(x) 
    if verbosity > 0
        println(x)
    end
end

end
