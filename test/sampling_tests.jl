using Turing, MCMCChains, KernelDensity, Test, Statistics
import StatsBase: sample, AbstractWeights

@testset "sampling api" begin

  @model gdemo(x) = begin
      m ~ Normal(1, 0.01)
      s ~ Normal(5, 0.01)
  end

  model = gdemo([1.5, 2.0])
  sampler = HMC(500, 0.01, 5)
  chn = sample(model, sampler, save_state=true);

  chn_sample = sample(chn, 5)
  @test range(chn_sample) == 1:1:5

  c = kde(reshape(convert(Array{Float64}, chn[:s].value), 500))
  chn_weighted_sample = sample(c.x, Weights(c.density), 100000)

  @test 4.9 < mean(reshape(convert(Array{Float64}, chn[:s].value), 500)) < 5.1

end