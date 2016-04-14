function cjt(c::AbstractVector,plan::ChebyshevJacobiPlan)
    α,β = getplanαβ(plan)
    N = length(c)
    N ≤ 1 && return c
    if α^2 == 0.25 && β^2 == 0.25
        ret = copy(c)
        if α == -0.5 && β == 0.5
            decrementβ!(ret,α,β)
        elseif α == 0.5 && β == -0.5
            decrementα!(ret,α,β)
        elseif α == 0.5 && β == 0.5
            decrementαβ!(ret,α,β)
        end
        for i=1:N ret[i] *= Cx(i-1.0)/sqrtpi end
        return ret
    else
        # General half-open square
        ret = tosquare!(copy(c),α,β)
        ret = jac2cheb(ret,modαβ(α),modαβ(β),plan)
        return ret
    end
end

function cjt(c::AbstractVector,plan::ChebyshevUltrasphericalPlan)
    λ = getplanλ(plan)
    N = length(c)
    N ≤ 1 && return c
    if λ == 0 || λ == 1
        ret = copy(c)
        λ == 1 && decrementαβ!(ret,λ-one(λ)/2,λ-one(λ)/2)
        for i=1:N ret[i] *= Cx(i-1.0)/sqrtpi end
        return ret
    else
        # Ultraspherical line
        ret = toline!(copy(c),λ-one(λ)/2,λ-one(λ)/2)
        ret = ultra2cheb(ret,modλ(λ),plan)
        return ret
    end
end

function icjt(c::AbstractVector,plan::ChebyshevJacobiPlan)
    α,β = getplanαβ(plan)
    N = length(c)
    N ≤ 1 && return c
    if α^2 == 0.25 && β^2 == 0.25
        ret = copy(c)
        for i=1:N ret[i] *= sqrtpi/Cx(i-1.0) end
        if α == -0.5 && β == 0.5
            incrementβ!(ret,α,β-1)
            return ret
        elseif α == 0.5 && β == -0.5
            incrementα!(ret,α-1,β)
            return ret
        elseif α == 0.5 && β == 0.5
            incrementαβ!(ret,α-1,β-1)
            return ret
        else
            return ret
        end
    else
        # General half-open square
        ret = cheb2jac(c,modαβ(α),modαβ(β),plan)
        fromsquare!(ret,α,β)
        return ret
    end
end

function icjt(c::AbstractVector,plan::ChebyshevUltrasphericalPlan)
    λ = getplanλ(plan)
    N = length(c)
    N ≤ 1 && return c
    if λ == 0 || λ == 1
        ret = copy(c)
        for i=1:N ret[i] *= sqrtpi/Cx(i-1.0) end
        λ == 1 && incrementαβ!(ret,λ-3one(λ)/2,λ-3one(λ)/2)
        return ret
    else
        # Ultraspherical line
        ret = cheb2ultra(c,modλ(λ),plan)
        fromline!(ret,λ-one(λ)/2,λ-one(λ)/2)
        return ret
    end
end

jjt(c,α,β,γ,δ) = icjt(cjt(c,α,β),γ,δ)

function plan_cjt(c::AbstractVector,α,β;M::Int=7)
    α == β && return plan_cjt(c,α+one(α)/2;M=M)
    P = ForwardChebyshevJacobiPlan(c,modαβ(α),modαβ(β),M)
    P.CJC.α,P.CJC.β = α,β
    P
end
function plan_icjt(c::AbstractVector,α,β;M::Int=7)
    α == β && return plan_icjt(c,α+one(α)/2;M=M)
    P = BackwardChebyshevJacobiPlan(c,modαβ(α),modαβ(β),M)
    P.CJC.α,P.CJC.β = α,β
    P
end

function plan_cjt(c::AbstractVector,λ;M::Int=7)
    P = ForwardChebyshevUltrasphericalPlan(c,modλ(λ),M)
    P.CUC.λ = λ
    P
end
function plan_icjt(c::AbstractVector,λ;M::Int=7)
    P = BackwardChebyshevUltrasphericalPlan(c,modλ(λ),M)
    P.CUC.λ = λ
    P
end

for (op,plan_op,D) in ((:cjt,:plan_cjt,:FORWARD),(:icjt,:plan_icjt,:BACKWARD))
    @eval begin
        $op(c,α,β) = $plan_op(c,α,β)*c
        $op(c,λ) = $plan_op(c,λ)*c
        *{T<:AbstractFloat}(p::FastTransformPlan{$D,T},c::AbstractVector{T}) = $op(c,p)
        $plan_op{T<:AbstractFloat}(c::AbstractVector{Complex{T}},α,β;M::Int=7) = $plan_op(real(c),α,β;M=M)
        $plan_op{T<:AbstractFloat}(c::AbstractVector{Complex{T}},λ;M::Int=7) = $plan_op(real(c),λ;M=M)
        $plan_op(c::AbstractMatrix,α,β;M::Int=7) = $plan_op(slice(c,1:size(c,1)),α,β;M=M)
        $plan_op(c::AbstractMatrix,λ;M::Int=7) = $plan_op(slice(c,1:size(c,1)),λ;M=M)
    end
end

function *{D,T<:AbstractFloat}(p::FastTransformPlan{D,T},c::AbstractVector{Complex{T}})
    cr,ci = reim(c)
    complex(p*cr,p*ci)
end

function *(p::FastTransformPlan,c::AbstractMatrix)
    m,n = size(c)
    ret = zero(c)
    for j=1:n ret[:,j] = p*slice(c,1:m,j) end
    ret
end

"""
    cjt(c,α,β)

Computes the Chebyshev expansion coefficients
given the Jacobi expansion coefficients ``c`` with parameters ``α`` and ``β``.

See also [`icjt`](:func:`icjt`) and [`jjt`](:func:`jjt`).
"""
cjt

"""
    icjt(c,α,β)

Computes the Jacobi expansion coefficients with parameters ``α`` and ``β``
given the Chebyshev expansion coefficients ``c``.

See also [`cjt`](:func:`cjt`) and [`jjt`](:func:`jjt`).
"""
icjt

"""
    jjt(c,α,β,γ,δ)

Computes the Jacobi expansion coefficients with parameters ``γ`` and ``δ``
given the Jacobi expansion coefficients ``c`` with parameters ``α`` and ``β``.

See also [`cjt`](:func:`cjt`) and [`icjt`](:func:`icjt`).
"""
jjt

"""
    plan_cjt(c,α,β;M=7)

Pre-plan optimized DCT-I and DST-I plans and pre-allocate the necessary
arrays, normalization constants, and recurrence coefficients for a forward Chebyshev—Jacobi transform.

``c`` is the vector of coefficients; and,

``α`` and ``β`` are the Jacobi parameters.

Optionally:

``M`` determines the number of terms in Hahn's asymptotic expansion.
"""
plan_cjt

"""
    plan_icjt(c,α,β;M=7)

Pre-plan optimized DCT-I and DST-I plans and pre-allocate the necessary
arrays, normalization constants, and recurrence coefficients for an inverse Chebyshev—Jacobi transform.

``c`` is the vector of coefficients; and,

``α`` and ``β`` are the Jacobi parameters.

Optionally:

``M`` determines the number of terms in Hahn's asymptotic expansion.
"""
plan_icjt
