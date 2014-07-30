from sys import argv,stdout,stdin
from openalea.aml import MTG, VtxList, Trunk, Feature
from openalea.core.alea import load_package_manager, function
from numpy import mean, array

pm = load_package_manager()
nf = pm['__my package__']['singlehistogram']
histogram = function(nf)

#get mtg file name
#mfile=argv[1]
mfile='ModelMTG.mtg'

m=MTG(mfile)
branches=VtxList(Scale=2)
nodes=VtxList(Scale=3)

nodelen=[] # in cm

for n in nodes[1:len(nodes)]: #skip first node /P1/S1
	fl=Feature(n,'ILength')
	if fl >0:
		nodelen.append(fl/10.0)

nbins=10
set1=array(nodelen)
histogram(set1,nbins,'Node Length (cm)')
