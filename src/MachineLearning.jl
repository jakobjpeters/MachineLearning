    
module MachineLearning

include("math.jl")
include("types.jl")
include("functors.jl")
include("utilities.jl")
include("interface.jl")
include("core.jl")

export
    # math.jl
    derivative, mean, # general
    sigmoid, relu, # activation
    softmax, squared_error, # cost
    z_score, demean, # standardization
    xavier, he, # weight initialization
    weight_decay, l1, l2, # regularization

    # interface.jl
    terminal,

    # core.jl
    train!,
    assess,

    # types.jl
    Assessment, Dataset, # 
    LayerParameters, EpochParameters, Cache,
    NeuralNetwork, Dense, Linear, # models

    # utilities.jl
    load_dataset, split_dataset

end # module
