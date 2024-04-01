################################################################################
#                                                                              #
#                                 OptiMode.jl:                                 #
#                Differentiable Electromagnetic Eigenmode Solver               #
#                                 (an attempt)                                 #
#                                                                              #
################################################################################

module OptiMode

##### Imports ######

### Linear Algebra Types and Libraries ###
using LinearAlgebra
using LinearAlgebra: diag
using LinearMaps
using ArrayInterface
using StaticArrays
using StaticArrays: Dynamic, SVector
using HybridArrays
using FFTW
using AbstractFFTs
using LoopVectorization
using Tullio
using SliceMap

### AD ###
using ChainRulesCore
using ChainRulesCore: @thunk, @non_differentiable, @not_implemented, NoTangent, ZeroTangent, AbstractZero
using Zygote
using Zygote: Buffer, bufferfrom, @ignore, @adjoint, ignore, dropgrad, forwarddiff, Numeric, literal_getproperty, accum


### Materials ###
using Rotations
using Symbolics
using SymbolicUtils
using Symbolics
using Symbolics: Sym, Num, scalarize
using SymbolicUtils: @rule, @acrule, RuleSet, numerators, denominators, flatten_pows
using SymbolicUtils.Rewriters: Chain, RestartedChain, PassThrough, Prewalk, Postwalk
using IterTools: subsets
using RuntimeGeneratedFunctions
RuntimeGeneratedFunctions.init(@__MODULE__)

### Geometry ###
using GeometryPrimitives

### Iterative Solvers ###
using IterativeSolvers
using KrylovKit
# using DFTK: LOBPCG
using Roots

### Visualization ###
using Colors
using Colors: Color, RGB, RGBA, @colorant_str
import Colors: JULIA_LOGO_COLORS
logocolors = JULIA_LOGO_COLORS

### I/O ###
using Dates
using HDF5
using DelimitedFiles
using EllipsisNotation
using Printf
using ProgressMeter
# using Distributed

### Utils ###
using Logging

# Import methods that we will overload for custom types
import Base: size, eltype
import LinearAlgebra: mul!
import ChainRulesCore: rrule

## FFTW settings
# Set environment variable `OPTIMODE_NUM_THREADS` to increase number of threads.
# Default = 1, chosen for thread safety when combined with other parallel code, consider increasing
fftw_threads = haskey(ENV, "OPTIMODE_NUM_THREADS") ? ENV["OPTIMODE_NUM_THREADS"] : 1
# fftw_threads = 1
FFTW.set_num_threads(fftw_threads)

## Add methods to external packages ##
LinearAlgebra.ldiv!(c,A::LinearMaps.LinearMap,b) = mul!(c,A',b)


### Includes ###
include("logging.jl")
include("linalg.jl")
include("epsilon.jl")
include("materials.jl")
include("grid.jl")
include("geometry.jl")
include("cse.jl")
include("epsilon_fns.jl")
include("smooth.jl")
include("maxwell.jl")
include("fields.jl")
include("solve.jl")
include("grads/StaticArrays.jl")
include("grads/solve.jl")


include("solvers/iterativesolvers.jl")
include("solvers/krylovkit.jl")
include("solvers/dftk.jl")

end
