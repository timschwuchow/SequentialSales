#!/usr/bin/env python3 

from numpy import zeros
from math import sqrt

class Hex:
    '''
    Hexes create their neighbors and iteratively distribute probability between themselves from a given starting point.
    '''
    def __init__(self,n,m,steps=64,hexList=[]):
        '''
        Initialize based on converted cartesian coordinates 
        '''
        self.n = n 
        self.m = m
        self.x = n*0.5*sqrt(3)
        self.y = m
        self.d = sqrt(self.x**2.0 + self.y**2.0)
        self.steps = steps
        self.stepprobdist = zeros(steps+1)
        self.neighbors = []
        self.nlist = [(n,m+1), (n,m-1), (n+1,m+0.5), (n+1,m-0.5), (n-1,m+0.5), (n-1,m-0.5)]
        self.hexList = hexList
        self.hexList.append(self)

    def __print__(self):
        print("Hex[%d,%d]" % (self.n,self.m))

    def construct_neighbors(self):
        '''
        Construct neighbors if missing
        '''
        # First check existing hexlist for neighbors and add any not included
        for h in self.hexList:
            if not h in self.neighbors:
                if (h.n,h.m) in self.nlist:
                    self.neighbors.append(h)
        # If all neighbors were not in current list, make them and add them to local neighbor list and global hex list
        if len(self.neighbors) < 6:
            currentNeighbors = [(h.n,h.m) for h in self.neighbors]
            for nm in self.nlist:
                if not nm in currentNeighbors:
                    self.neighbors.append(Hex(nm[0],nm[1],steps=self.steps, hexList=self.hexList))

    def distribute_probability(self, step):

        cprob = self.stepprobdist[step]
        for h in self.neighbors:
            h.stepprobdist[step+1] += cprob / 6.0



hlist = []
NSTEP = 64
horigin = Hex(n=0, m=0, steps=NSTEP, hexList=hlist)
horigin.stepprobdist[0] = 1.0

for i in range(NSTEP):
    print("Computing step %d" %i)
    hl2 = hlist.copy()
    for h in hl2:
        h.construct_neighbors()
    for h in hlist:
        h.distribute_probability(i)


# Part 1/2: EV and SD after 16 steps

ev16 = sum([h.stepprobdist[16]*h.d for h in hlist])
sd16 = sqrt(sum([h.stepprobdist[16]*(h.d-ev16)**2 for h in hlist]))

# Part 3/4:

ev64 = sum([h.stepprobdist[64]*h.d for h in hlist])
sd64 = sqrt(sum([h.stepprobdist[64]*(h.d-ev64)**2 for h in hlist]))

# Parts 5/6

p6_16 = sum([h.stepprobdist[16]*(h.d >= 6) for h in hlist])
p8_16 = sum([h.stepprobdist[16]*(h.d >= 8) for h in hlist])

cprob16 = p8_16/p6_16


p24_64 = sum([h.stepprobdist[64]*(h.d >= 24) for h in hlist])
p20_64 = sum([h.stepprobdist[64]*(h.d >= 20) for h in hlist])

cprob64 = p24_64/p20_64

print("Question 1: %.10f\nQuestion 2: %.10f\nQuestion 3: %.10f\nQuestion 4: %.10f\nQuestion 5: %.10f\nQuestion 6: %.10f" % (ev16,sd16,ev64,sd64,cprob16,cprob64))



