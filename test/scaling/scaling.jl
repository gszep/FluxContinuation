######################################################## model
F(z::BorderedArray,θ::AbstractVector,N::Int,M::Int) = F(z.u,(θ=θ,p=z.p),N::Int,M::Int)
function F(u::AbstractVector{T},parameters::NamedTuple,N::Int,M::Int) where T<:Number

	@unpack θ,p = parameters
	f = first(u)*first(p)*first(θ)
	F = zeros(typeof(f),length(u))

	F[1] = sin(p)^2 - ( θ[1]*sin(p)^2 + 1 )*u[1]
	for i ∈ 2:N
		F[i] = u[i-1] - u[i]
	end

	for i ∈ 2:M
		F[1+mod(i-1,N)] -= u[1+mod(i-1,N)]*θ[i]
	end

	return F
end

function scaling_backward(N::Int,M::Int)
	f(u,p) = F(u,p,N,M)

	X = StateSpace(N,-π:0.01:π,[0.0])
	θ = SizedVector{M}(ones(M))

	println("N = $N M = $M")
	@time ∇loss(f,θ,X)
	return @elapsed ∇loss(f,θ,X)
end

function scaling_forward(N::Int,M::Int)
	f(u,p) = F(u,p,N,M)

	X = StateSpace(N,-π:0.01:π,[0.0])
	θ = SizedVector{M}(ones(M))

	println("N = $N M = $M")
	@time loss(f,θ,X)
	return @elapsed loss(f,θ,X)
end

function scaling_continuation(N::Int,M::Int)
	f(u,p) = F(u,p,N,M)

	X = StateSpace(N,-π:0.01:π,[0.0])
	parameters = (θ=SizedVector{M}(ones(M)),p=minimum(X.parameter))
	hyperparameters = getParameters(X)

	println("N = $N M = $M")
	@time deflationContinuation(f,X.roots,parameters,hyperparameters)
	return @elapsed deflationContinuation(f,X.roots,parameters,hyperparameters)
end