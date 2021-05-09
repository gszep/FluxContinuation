######################################################## unit test
∧(u::AbstractVector,v::AbstractVector) = u*v' - v*u'

function random_test(rates::Function,targetData::StateSpace; nSamples::Int=25,
	order::Int=5, condition::Int=100, geom::Bool=true, tolerance::Number=2e-2)
	hyperparameters = getParameters(targetData)

	function finite_differences(θ::AbstractVector{<:Number})
		return first(grad(central_fdm(order,1,geom=geom,condition=condition),
			θ -> loss(rates,θ,targetData,hyperparameters), θ ))
	end

	function autodiff(θ::AbstractVector{<:Number})
		L,∇L = ∇loss(rates,θ,targetData,hyperparameters)
		return ∇L
	end

	samples,errors = [ convert(typeof(θ),randn(length(θ))) for _ ∈ 1:nSamples ], fill(NaN,nSamples)
	Threads.@threads for i = 1:nSamples
		try 
			errors[i] = norm( autodiff(samples[i]) ∧ finite_differences(samples[i]) ) / norm(finite_differences(samples[i]))
		catch error
			printstyled(color=:red,"$error\n")
		end
	end

	println("Median Error $(round(median(errors[.~isnan.(errors)]),digits=2))% for $(length(errors[.~isnan.(errors)])) samples")
	return isapprox(median(errors[.~isnan.(errors)]),0,atol=tolerance)
end