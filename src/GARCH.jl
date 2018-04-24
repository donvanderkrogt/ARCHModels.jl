export GARCH
struct GARCH{p, q} <: VolatilitySpec end

@inline nparams{p, q}(M::Type{GARCH{p,q}}) = p+q+1

@inline presample{p, q}(M::Type{GARCH{p,q}}) = max(p, q)

@inline function update!{p, q}(M::Type{GARCH{p,q}}, data, ht, coefs, t)
    @fastmath begin
        ht[t] = coefs[1]
        for i = 1:p
            ht[t] += coefs[i+1]*ht[t-i]
        end
        for i = 1:q
            ht[t] += coefs[i+1+p]*data[t-i]^2
        end
    end
end
@inline function uncond{p, q, T}(M::Type{GARCH{p, q}}, coefs::Vector{T})
    @fastmath begin
        den=one(T)
        for i = 1:p+q
            den -= coefs[i+1]
        end
        h0 = coefs[1]/den
    end
end

function startingvals{p, q, T<:FP}(G::Type{GARCH{p,q}}, data::Array{T})
    x0 = zeros(T, p+q+1)
    x0[2:p+1] = 0.9/p
    x0[p+2:end] = 0.05/q
    x0[1] = var(data)*(one(T)-sum(x0))
    return x0
end

function constraints{p, q, T<:FP}(G::Type{GARCH{p,q}}, data::Array{T})
    lower = zeros(T, p+q+1)
    upper = ones(T, p+q+1)
    upper[1] = T(Inf)
    return lower, upper
end

function coefnames{p, q}(::Type{GARCH{p,q}})
    names = Array{String, 1}(p+q+1)
    names[1]="omega"
    names[2:p+1].=(i->"beta_$i").([1:p...])
    names[p+2:p+q+1].=(i->"alpha_$i").([1+q...])
    return names
end
