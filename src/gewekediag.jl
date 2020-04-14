#################### Geweke Diagnostic ####################

function gewekediag(x::Vector{<:Real}; first::Real=0.1, last::Real=0.5,
                             etype=:imse, args...)
  if !(0.0 < first < 1.0)
    throw(ArgumentError("first is not in (0, 1)"))
  elseif !(0.0 < last < 1.0)
    throw(ArgumentError("last is not in (0, 1)"))
  elseif first + last > 1.0
    throw(ArgumentError("first and last proportions overlap"))
  end
  n = length(x)
  x1 = x[1:round(Int, first * n)]
  x2 = x[round(Int, n - last * n + 1):n]
  z = (mean(x1) - mean(x2)) /
      sqrt(mcse(x1, etype; args...)^2 + mcse(x2, etype; args...)^2)
  [z, 1 - erf(abs(z) / sqrt(2))]
end

function gewekediag(chn::Chains; first::Real=0.1, last::Real=0.5,
                    etype=:imse,
                    sections::Union{Symbol, Vector{Symbol}}=Symbol[:parameters],
                    showall=false,
                    args...)
    c = showall ? chn : Chains(chn, _clean_sections(chn, sections))

    _, p, m = size(c.value)
    diags = [Array{Float64}(undef, p, 2) for _ in 1:m]
    for j in 1:p, k in 1:m
        diags[k][j,:] = gewekediag(
                            collect(skipmissing(c.value[:, j, k])),
                            first=first,
                            last=last,
                            etype=etype;
                            args...
                        )
    end

    # Obtain names of parameters.
    names_of_params = names(chn)

    # Compute data frames.
    vector_of_df = [
        ChainDataFrame(
            "Geweke Diagnostic - Chain $i",
            (parameters = names_of_params, zscore = d[:, 1], pvalue = d[:, 2])
        )
        for (i, d) in enumerate(diags)
    ]

    return vector_of_df
end
