
struct Data{T, S<:Integer}
    inputs::T
    labels::T
    length::S
end

function Data(inputs, labels)
    if length(inputs) != length(labels)
        throw(ErrorException("inputs and labels must be the same length"))
    end

    Data(inputs, labels, length(inputs))
end

function split_data(inputs, labels, splits)
    if sum(splits) != 100
        throw(ErrorException("Splits must add to 100 (percent)"))
    end

    starts = Vector{Int64}()
    i = 0
    for split in splits
        if i < 100
            append!(starts, div(i * length(inputs), 100))
        end
        i += split
    end
    stops = append!(starts[begin + 1:end], length(inputs))

    return [Data(view(inputs, start + 1:stop), view(labels, start + 1:stop)) for (start, stop) in zip(starts, stops)]
end

function split_data(data, splits)
    return split_data(data.inputs, data.labels, splits)
end

struct Epoch # {T<:Integer}
    batch_size # ::T
    shuffle::Bool

    Epoch(; batch_size = 1, shuffle = true) = new(batch_size, shuffle)
end

function (epoch::Epoch)(model, inputs, labels)
    if epoch.shuffle && epoch.batch_size != model.input_size
        inputs, labels = shuffle_data(inputs, labels)
    end

    for i in 1:epoch.batch_size:length(inputs)
        backpropagate!(model, view(inputs, i:i + epoch.batch_size - 1), view(labels, i:i + epoch.batch_size - 1))
    end
end

struct Layer

end

abstract type Model end

struct FFN
    cost_func
    input_size
    precision
    weight_init_funcs
    norm_funcs
    activ_funcs
    learn_rates
    sizes
    use_biases::Vector{Bool}
    weights
    biases
    δl_δw
    δl_δb
    activations
    Zs
end

function FFN(cost_func, input_size, precision, weight_init_funcs, norm_funcs, activ_funcs, learn_rates, sizes, use_biases)
    tmp_sizes = input_size, sizes...

    weights = [convert(Matrix{precision},
        rand(weight_init_func(input_size), output_size, input_size))
            for (weight_init_func, input_size, output_size) in zip(weight_init_funcs, tmp_sizes[begin:end - 1], tmp_sizes[begin + 1:end])]
    biases = [use_bias ? zeros(precision, size) : nothing for (use_bias, size) in zip(use_biases, sizes)]

    FFN(
        cost_func,
        input_size,
        precision,
        weight_init_funcs,
        norm_funcs,
        activ_funcs,
        learn_rates,
        sizes,
        use_biases,
        weights,
        biases,
        [convert(Matrix{precision},
            rand(weight_init_func(input_size), output_size, input_size))
            for (weight_init_func, input_size, output_size) in zip(weight_init_funcs, tmp_sizes[begin:end - 1], tmp_sizes[begin + 1:end])],
        deepcopy(biases),
        [zeros(precision, size) for size in tmp_sizes],
        [zeros(precision, size) for size in tmp_sizes]
    )
end

function (model::FFN)(input)
    model.activations[begin] = input

    for layer_n in 1:length(model.sizes)
        model.activations[layer_n] = model.norm_funcs[layer_n](model.activations[layer_n])

        model.Zs[layer_n] = model.weights[layer_n] * model.activations[layer_n]
        if model.use_biases[layer_n]
            model.Zs[layer_n] += model.biases[layer_n]

        model.activations[layer_n + 1] = model.activ_funcs[layer_n](model.Zs[layer_n])
        end
    end
end

struct GAN <: Model
    generator
    discriminator
end
