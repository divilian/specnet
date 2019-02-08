
module Misc

export pri, prd, verbosity

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
