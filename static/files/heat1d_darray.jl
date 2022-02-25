# This program solves the 1D diffusion equation on a finite interval
# [-L,L] for t > 0
#
#     u = au   ,  on (-L,L), u(x,0) = f(x), u(-L,t) = 0, u(L,t) = 0
#      t    xx
#
# where the initial condition f(x) takes the form
#
#     f(x) = 1 on -0.1 <= x <= 0.1 and f(x) = 0 elsewhere
#
# using the explicit finite difference approach on a set of equally
# spaced mesh points
#                                ___
#                               |   | f(x)
#                               |   |
#                               |   |
#                               |   |
#                               |   |
#           ---------------------------------------------
#          -L                 -0.1 0.1                  L
#
#           o---*---*---*---*---*---*---*---*---*---*---o
#           1   2                                       N
#
# The solution of u(x,t) is approximated by the values computed at grid
# points x , i=1,...,N at different time step t  stored in an one dimensional 
#         i                                    j
# array U updated successively
#
#     n+1           n       n      n
#    U   = (1 - 2k)U  + k*(U    + U   )
#     i             i       i-1    i+1
#
#        j
# where U  represents the value at x  at time t  and k < 0.5 is a parameter.
#        i                          i          j
#
# The finite difference grid is illustrated below
#
#     1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17
#     o--x--x--x--x--x--x--x--x--x--x--x--x--x--x--x--o
#    -L                                               L
#
# The grid of points is partitioned among processes (without overlap) 
# as evenly as possible
#
#     1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17
#    [o--x--x--x][x--x--x--x][x--x--x--x][x--x--x--x--o]
#    [     1    ][     2    ][     3    ][     4       ]
#
# In the code below, a single one dimensional array u is used. Vectorized 
# operations take place on the right hand side (RHS)
#
#    u[is:ie] = (1.0-2.0*k)*u[is:ie] + k*(u[is-1:ie-1]+u[is+1:ie+1]) 
#
# where is and ie are respectively the start and end indices of the grid 
# points on a subinterval. The values of u on the left hand side are then 
# updated. No in-place updates take place in u during the vectorized 
# operations on the RHS.
#
# This is a toy example for the purpose of demonstrating the use of shared
# arrays only. One should not use it without considering both the numerical
# and performance issues.
#
# Copyrigh(C) 2020 Western University
# Ge Baolai <gebaolai@gmail.com>
# Western University
# Faculty of Science | SHARCNET | Compute Canada 

using Base, Distributed, DistributedArrays
using Plots

# Input parameters
a = 1.0
n = 65			# Number of end points 1 to n (n-1 intervals).
dt = -0.0005 		# dt <= 0.5*dx^2/a, ignored if set negative
k = 0.01
num_steps = 10000       # Number of stemps in t.
output_freq = 1		# Number of stemps per display.
xlim = zeros(Float64,2)
xlim[1] = -1.0
xlim[2] = 1.0
heat_range = zeros(Float64,2)
heat_range[1] = -0.1
heat_range[2] = 0.1
heat_temp = 1.0

# Set the k value
dx = (xlim[2] - xlim[1])/(n-1)
if (dt > 0)
    k = a*dt/(dx*dx)
end

# Set x-coordinates for plot
x = xlim[1] .+ dx*(collect(1:n) .-1);

# Allocate spaces
@everywhere using DistributedArrays
u = dzeros(Float64,n);

# Broadcast parameters to all
@everywhere k=$k
@everywhere n=$n
@everywhere heat_temp=$heat_temp
@everywhere u=$u

# Define gloabl vars and functions on all worker processes
@everywhere using Distributed, DistributedArrays
@everywhere ilo=1
@everywhere iup=1
@everywhere l1=1
@everywhere ln=1 # Local start and end indices

# Get lower and upper indices of array u owned by this process
@everywhere function get_partition_info()
    global u;
    global l1, ln, ilo, iup;

    # Get the lower and upper boundary indices from distributed array
    idx = localindices(u);
    index_range = idx[1];
    ilo = index_range.start;
    iup = index_range.stop;
    l1 = ilo;
    ln = iup;

    # Local compute end indices (skip the left and right most end points)
    me = myid() - 1
    if (me == 1) 
        l1 = 2;
    end
    if (me == nworkers())
        ln = iup - 1;
    end
end

# Show partition info
@everywhere function show_partition_info()
    global ilo, iup, l1, ln;
    println("ilo=",ilo,", iup=",iup,", l1=",l1,", ln=",ln)
end

# Define the function to compute the soluton on a process
@everywhere function update()
    global u, ilo, iup, l1, ln;
    global k;

    # Compute updated solution for the next time steop
    # The line below does not work: method setting value not defined
    #u[l1:ln] = (1.0-2.0*k)*u[l1:ln] + k*(u[l1-1:ln-1]+u[l1+1:ln+1])
    ll1 = l1 - ilo + 1;
    lln = ln - ilo + 1;
    u.localpart[ll1:lln] = (1.0-2.0*k)*u[l1:ln] + k*(u[l1-1:ln-1]+u[l1+1:ln+1])
end

# Set initial condition
ihot = findall(x->(heat_range[1] .< x .&& x .< heat_range[2]),x);
@everywhere ihot=$ihot

# Set the initial condition within this process
@everywhere function set_init_cond()
    global ihot;
    global ilo, iup;
    global u;
    global heat_temp;

    # Find the intersection of [ilo,iup] and ihot within this process
    ihot_local = intersect(ihot,Vector(ilo:iup));
    if (length(ihot_local) == 0) 
        return
    end
    istart = ihot_local[1] - ilo + 1;
    iend = ihot_local[end] - ilo + 1;
    
    # Set the initial condition within this process
    u.localpart[istart:iend] .= heat_temp;
end

# Initialize variables and set initial conditions
for p in workers()
    @async remotecall_fetch(get_partition_info,p)
end
for p in workers()
    @async remotecall_fetch(set_init_cond,p)
end

# Display the initial value of u
v = zeros(Float64,n)
v .= u;
display(plot(x,v,lw=3,ylim=(0,1),label=("u")))

# Update u in time on workders
@time begin
for j=1:num_steps 
    @sync begin
        for p in workers()
            @async remotecall_fetch(update,p);
        end
    end           
    if (j % output_freq == 0)
        v .= u;
        display(plot(x,v,lw=3,ylim=(0,1),label=("u")))
    end
end
end

sleep(10)
