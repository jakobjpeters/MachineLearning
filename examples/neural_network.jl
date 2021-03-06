
# internal
using MachineLearning

# external
using Random: seed!

# testing
using InteractiveUtils: @which, @code_warntype

function main()
    # [Float32, Float64]
    # default is Float32
    precision = Float32

    # comment out for random seed
    seed!(1)

    # Dataset
    # EMNIST
    # ["mnist", "balanced", "digits", "bymerge", "byclass", "letters"]
    # "letters" is broken
    dataset_name = "mnist"

    # [z_score, demean, identity]
    preprocessor = z_score

    split_percentages = [80, 20]

    # dataset = load_dataset(dataset_name, preprocessor, split_percentages, precision)

    dataset = load_dataset(dataset_name, preprocessor, precision)
    dataset = split_dataset(dataset.x, dataset.y, split_percentages)


    # Model
    # [xavier, he]
    # 'he' is untested
    w_inits = [xavier, xavier]

    # TODO: make dynamic
    input_size = 784

    # the last layer size is determined by the number of classes
    # TODO: make last layer size dynamic
    layer_sizes = [100, 10]

    # [true, false]
    use_biases = [true, false]

    # ["Neural_Network", "Linear"]
    model = NeuralNetwork(
        input_size,
        w_inits,
        layer_sizes,
        use_biases,
        precision
    )

    caches = map(_ -> Cache(precision), eachindex(model.layers))


    # Layers_Parameters
    # [tanh, sigmoid, identity]
    # 'identity' is untested
    activators = [sigmoid, sigmoid]

    # [weight_decay, l1, l2]
    # default is "weight_decay"
    # untested
    regularizers = [weight_decay, weight_decay]

    # set to '0.0' for no regularization
    # untested
    regularize_rates = [0.0, 0.0]

    learn_rates = [0.1, 0.01]

    # layer normalization
    # [z_score, demean, identity]
    # not currently "plugged in"
    layer_normalizers = [identity, identity]

    layers_params = zip(layer_normalizers, activators, regularizers, regularize_rates, learn_rates)
    layers_params = map(layer_params -> LayerParameters(layer_params..., precision), layers_params)


    # Epoch
    # [squared_error]
    loss = squared_error

    # batch normalization
    # [z_score, demean, identity]
    batch_normalizer = z_score

    n_epochs = 10
    batch_size = 10
    shuffle_data = true

    epoch_params = EpochParameters(batch_size, shuffle_data, loss, batch_normalizer, layers_params)

    # pre-trained
    assessments = [assess(dataset, model, epoch_params.loss, epoch_params.layers_params)]
    terminal(assessments)

    # main training loop
    @time for i in 1:n_epochs
        # see 'core.jl'
        @time train!(epoch_params, model, caches, dataset[begin].x, dataset[begin].y)

        @time assessment = assess(dataset, model, epoch_params.loss, epoch_params.layers_params)
        push!(assessments, assessment)

        # see 'interface.jl'
        terminal(assessments)
    end

end

main()