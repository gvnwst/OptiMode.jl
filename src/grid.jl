"""
##############################################################################################
#																			   				 #
#		Define a spatial Grid type and utility/convenience functions acting on Grids		 #
#																			   				 #
##############################################################################################
"""

export Grid, δx, δy, δz, δ, x, y, z, x⃗, xc, yc, zc, x⃗c, N, g⃗, _fftaxes, Nranges, ∫, corners, vxlmin, vxlmax

struct Grid{ND,T}
	Δx::T
    Δy::T
    Δz::T
	Nx::Int
    Ny::Int
    Nz::Int
end

Grid(Δx::T, Δy::T, Δz::T, Nx::Int, Ny::Int, Nz::Int) where {T<:Real} = Grid{3,T}(
	Δx,
    Δy,
    Δz,
	Nx,
    Ny,
    Nz,
)

Grid(Δx::T, Δy::T, Nx::Int, Ny::Int) where {T<:Real} = Grid{2,T}(
	Δx,
    Δy,
    1.,
	Nx,
    Ny,
    1,
)




δx(g::Grid) = g.Δx / g.Nx
δy(g::Grid) = g.Δy / g.Ny
δz(g::Grid) = g.Δz / g.Nz

δ(g::Grid{2}) = g.Δx * g.Δy / ( g.Nx * g.Ny )
δ(g::Grid{3}) = g.Δx * g.Δy * g.Δz / ( g.Nx * g.Ny * g.Nz )

∫(intgnd;g::Grid) = sum(intgnd)*δ(g)	# integrate a scalar field over the grid

### Grid Points (Voxel/Pixel Center Positions) ###
function x(g::Grid{ND,T})::Vector{T}  where {ND,T<:Real}
 	# ( ( g.Δx / g.Nx ) .* (0:(g.Nx-1))) .- g.Δx/2.
	LinRange(-g.Δx/2, g.Δx/2 - g.Δx/g.Nx, g.Nx)
end
function y(g::Grid{ND,T})::Vector{T}  where {ND,T<:Real}
 	# ( ( g.Δy / g.Ny ) .* (0:(g.Ny-1))) .- g.Δy/2.
	LinRange(-g.Δy/2, g.Δy/2 - g.Δy/g.Ny, g.Ny)
end
function z(g::Grid{ND,T})::Vector{T}  where {ND,T<:Real}
 	# ( ( g.Δz / g.Nz ) .* (0:(g.Nz-1))) .- g.Δz/2.
	LinRange(-g.Δz/2, g.Δz/2 - g.Δz/g.Nz, g.Nz)
end
function x⃗(g::Grid{2,T})::Array{SVector{3,T},2} where T<:Real
	[ SVector{3,T}(xx,yy,zero(T)) for xx in x(g), yy in y(g) ] # (Nx × Ny ) 2D-Array of (x,y,z) vectors at pixel/voxel centers
end
function x⃗(g::Grid{3,T})::Array{SVector{3,T},3} where T<:Real
	[ SVector{3,T}(xx,yy,zz) for xx in x(g), yy in y(g), zz in z(g) ] # (Nx × Ny × Nz) 3D-Array of (x,y,z) vectors at pixel/voxel centers
end

import Base: ndims, length, size, firstindex, lastindex, eachindex, getindex, LinearIndices, CartesianIndices, Dims, iterate, eltype
### Size & Dimensionality ###
@inline size(gr::Grid{3})			=	(gr.Nx, gr.Ny, gr.Nz)
@inline size(gr::Grid{2})			=	(gr.Nx, gr.Ny)
@inline size(gr::Grid, d::Int) 		= 	getindex((gr.Nx, gr.Ny, gr.Nz),d)
@inline Dims(gr::Grid)				=	size(gr)
@inline N(g::Grid)::Int 			= 	prod(size(g))	# legacy, TODO: replace all instances of N(g::Grid) with size(g::Grid)
@inline length(g::Grid)::Int 		= 	prod(size(g))
@inline LinearIndices(g::Grid) 		= 	1:length(g)
@inline CartesianIndices(g::Grid) 	= 	CartesianIndices(size(g))
@inline firstindex(g::Grid)			=	1
@inline lastindex(g::Grid)			=	length(g)
@inline eachindex(g::Grid) 			= 	CartesianIndices(g) # 1:length(g) if you want to use LinearIndices by default

@inline function eltype(g::Grid{ND,T}) where {ND,T<:Real}
	return SVector{3,T}
end

@inline function ndims(g::Grid{ND}) where ND
	return ND
end

### Iteration ###
"""
iterate over a (Nx × Ny ) two dimensional grid of (x,y,z) vectors (of type `SVector{3}`) at pixel centers
"""
@inline function iterate(g::Grid{2,T}) where T<:Real
	iterate(( SVector{3,T}(xx,yy,zero(T)) for xx in x(g), yy in y(g) ))
end

@inline function iterate(g::Grid{2,T}, state) where T<:Real
	iterate(( SVector{3,T}(xx,yy,zero(T)) for xx in x(g), yy in y(g) ), state)
end

"""
iterate over a (Nx × Ny × Nz ) three dimensional grid of (x,y,z) vectors (of type `SVector{3}`) at voxel centers
"""
@inline function iterate(g::Grid{3,T}) where T<:Real
	iterate( ( SVector{3,T}(xx,yy,zz) for xx in x(g), yy in y(g), zz in z(g) ) )
end

@inline function iterate(g::Grid{3,T}, state) where T<:Real
	iterate( ( SVector{3,T}(xx,yy,zz) for xx in x(g), yy in y(g), zz in z(g) ), state )
end


### Indexing ###
function getindex(g::Grid{2,T}, I::CartesianIndex) where{T<:Real}
	# @inbounds SVector{3,T}(x(g)[I[1]],y(g)[I[2]],zero(T))
	@inbounds SVector{3,T}(
		g.Δx*((I[1]-1)*inv(g.Nx)-0.5),
		g.Δy*((I[2]-1)*inv(g.Ny)-0.5),
		zero(T),
	)
end

function getindex(g::Grid{2,T}, ix::Int, iy::Int) where{T<:Real}
	# @inbounds SVector{3,T}(x(g)[I[1]],y(g)[I[2]],zero(T))
	@inbounds SVector{3,T}(
		g.Δx*((ix-1)*inv(g.Nx)-0.5),
		g.Δy*((iy-1)*inv(g.Ny)-0.5),
		zero(T),
	)
end

function getindex(g::Grid{3,T}, I::CartesianIndex) where{T<:Real}
	# @inbounds SVector{3,T}(x(g)[I[1]],y(g)[I[2]],zero(T))
	@inbounds SVector{3,T}(
		g.Δx*((I[1]-1)*inv(g.Nx)-0.5),
		g.Δy*((I[2]-1)*inv(g.Ny)-0.5),
		g.Δz*((I[3]-1)*inv(g.Nz)-0.5),
	)
end

function getindex(g::Grid{3,T}, ix::Int, iy::Int, iz::Int) where{T<:Real}
	# @inbounds SVector{3,T}(x(g)[I[1]],y(g)[I[2]],zero(T))
	@inbounds SVector{3,T}(
		g.Δx*((ix-1)*inv(g.Nx)-0.5),
		g.Δy*((iy-1)*inv(g.Ny)-0.5),
		g.Δz*((iz-1)*inv(g.Nz)-0.5),
	)
end

@inline function getindex(g::Grid{ND,T}, idx::Int) where{ND,T<:Real}
	return getindex(g,CartesianIndices(g)[idx])
end

### Reciprocal Lattice Axes and Vectors (from fftfreqs) ###
@inline _fftaxes(gr::Grid{2}) = (2:3)
@inline _fftaxes(gr::Grid{3}) = (2:4)

function g⃗(gr::Grid{2,T})::Array{SVector{3, T}, 2} where T
	[	SVector(gx,gy,0.) for   gx in fftfreq(gr.Nx,gr.Nx/gr.Δx),
							   	gy in fftfreq(gr.Ny,gr.Ny/gr.Δy)		]
end

function g⃗(gr::Grid{3,T})::Array{SVector{3, T}, 3} where T<:Real
	[	SVector(gx,gy,gz) for   gx in fftfreq(gr.Nx,gr.Nx/gr.Δx),
								gy in fftfreq(gr.Ny,gr.Ny/gr.Δy),
							    gz in fftfreq(gr.Nz,gr.Nz/gr.Δz)		]
end

### Iterators Over Grid Voxel/Pixel Corner Positions ###

@inline function xc(g::Grid{ND,T})::Vector{T} where {ND,T<:Real}
	LinRange(-(g.Δx + δx(g))/2, (g.Δx - δx(g))/2, g.Nx+1)
end

@inline function yc(g::Grid{ND,T})::Vector{T} where {ND,T<:Real}
	LinRange(-(g.Δy + δy(g))/2, (g.Δy - δy(g))/2, g.Ny+1)
end

@inline function zc(g::Grid{ND,T})::Vector{T} where {ND,T<:Real}
	LinRange(-(g.Δz + δz(g))/2, (g.Δz - δz(g))/2, g.Nz+1)
end

@inline function x⃗c(g::Grid{2,T})  where T<:Real
	( SVector{3,T}(xx,yy,zero(T)) for xx in xc(g), yy in yc(g) )
end

@inline function x⃗c(g::Grid{3,T})  where T<:Real
	( SVector{3,T}(xx,yy,zz) for xx in xc(g), yy in yc(g), zz in zc(g) )
end

function corners(g::Grid{2,T}) where T<:Real
	# (	( 
	# 		xx + SVector{3,T}( -δx(g), -δy(g),	zero(T) ),
	# 		xx + SVector{3,T}( -δx(g),	δy(g),	zero(T) ),
	# 		xx + SVector{3,T}(	δx(g),	δy(g),	zero(T) ),
	# 		xx + SVector{3,T}(	δx(g), -δy(g),	zero(T) ),
	# 	) 	for xx in g 	)
	(	( 
		SVector{2,T}(xx[1:2]) + SVector{2,T}( -δx(g), -δy(g)  ),
		SVector{2,T}(xx[1:2]) + SVector{2,T}( -δx(g),	δy(g)  ),
		SVector{2,T}(xx[1:2]) + SVector{2,T}(	δx(g),	δy(g)  ),
		SVector{2,T}(xx[1:2]) + SVector{2,T}(	δx(g), -δy(g)  ),
	) 	for xx in g 	)
end

function corners(g::Grid{3,T}) where T<:Real
	(	( 
			xx + SVector{3,T}( -δx(g), -δy(g),	-δz(g) ),
			xx + SVector{3,T}( -δx(g),	δy(g),	-δz(g) ),
			xx + SVector{3,T}(	δx(g),	δy(g),	-δz(g) ),
			xx + SVector{3,T}(	δx(g), -δy(g),	-δz(g) ),
			xx + SVector{3,T}( -δx(g), -δy(g),	 δz(g) ),
			xx + SVector{3,T}( -δx(g),	δy(g),	 δz(g) ),
			xx + SVector{3,T}(	δx(g),	δy(g),	 δz(g) ),
			xx + SVector{3,T}(	δx(g), -δy(g),	 δz(g) ),
		) 	for xx in g 	)
end

@inline function vxlmin(g::Grid{2,T}) where T<:Real
	(	xx + SVector{3,T}( -δx(g), -δy(g),	zero(T) )	for xx in g		)
end

@inline function vxlmax(g::Grid{2,T}) where T<:Real
	(	xx + SVector{3,T}(  δx(g),  δy(g),	zero(T) )	for xx in g		)
end

@inline function vxlmin(g::Grid{3,T}) where T<:Real
	(	xx + SVector{3,T}( -δx(g), -δy(g), -δz(g) )		for xx in g		)
end

@inline function vxlmax(g::Grid{3,T}) where T<:Real
	(	xx + SVector{3,T}(  δx(g),  δy(g),	δz(g) )		for xx in g		)
end

@inline function vxlmin(crnrs::NTuple{NC,SVector{ND,T}}) where {NC,ND,T<:Real}
	first(crnrs)
end

@inline function vxlmax(crnrs::NTuple{4,SVector{ND,T}}) where {ND,T<:Real}
	@inbounds crnrs[3]
end

@inline function vxlmax(crnrs::NTuple{8,SVector{ND,T}}) where {ND,T<:Real}
	@inbounds crnrs[7]
end



# ### Grid Voxel/Pixel Corner Positions ###
# function xc(g::Grid{ND,T})::Vector{T} where {ND,T<:Real}
# 	( ( g.Δx / g.Nx ) .* (0:g.Nx) ) .- ( g.Δx/2. * ( 1 + 1. / g.Nx ) )
# 	# collect(range(-g.Δx/2.0, g.Δx/2.0, length=g.Nx+1))
# end
# function yc(g::Grid{ND,T})::Vector{T} where {ND,T<:Real}
# 	( ( g.Δy / g.Ny ) .* (0:g.Ny) ) .- ( g.Δy/2. * ( 1 + 1. / g.Ny ) )
# 	# collect(range(-g.Δy/2.0, g.Δy/2.0, length=g.Ny+1))
# end
# function zc(g::Grid{3,T})::Vector{T} where T<:Real
# 	( ( g.Δz / g.Nz ) .* (0:g.Nz) ) .- ( g.Δz/2. * ( 1 + 1. / g.Nz ) )
# 	# collect(range(-g.Δz/2.0, g.Δz/2.0, length=g.Nz+1))
# end
# function x⃗c(g::Grid{2,T})::Array{SVector{3,T},2}  where T<:Real
# 	# ( (xx,yy) = (xc(g),yc(g)); [SVector{3}(xx[ix],yy[iy],0.) for ix=1:(g.Nx+1),iy=1:(g.Ny+1)] )
# 	[ SVector{3,T}(xx,yy,zero(T)) for xx in xc(g), yy in yc(g) ]
# end
# function x⃗c(g::Grid{3,T})::Array{SVector{3,T},3}  where T<:Real
# 	# ( (xx,yy,zz) = (xc(g),yc(g),zc(g)); [SVector{3}(xx[ix],yy[iy],zz[iz]) for ix=1:(g.Nx+1),iy=1:(g.Ny+1),iz=1:(g.Nz+1)] )
# 	[ SVector{3,T}(xx,yy,zz) for xx in xc(g), yy in yc(g), zz in zc(g) ]
# end

"""
################################################################################
#																			   #
#							   Plotting methods					   			   #
#																			   #
################################################################################
"""
