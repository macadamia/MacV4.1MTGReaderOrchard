from sys import argv,stdout,stdin
from openalea.aml import MTG, VtxList, Trunk, Feature
from openalea.core.alea import load_package_manager, function
from numpy import mean, array

pm = load_package_manager()
nf = pm['__my package__']['twosethistogram']
histogram = function(nf)

#get mtg file name
#mfile=argv[1]
mfile='ModelMTG.mtg'

m=MTG(mfile)
branches=VtxList(Scale=2)
nodes=VtxList(Scale=3)
rat= len(nodes) / float(len(branches))
stdout.write('\nNode:Branch ratio is %.2f\n' % (rat))

numsegs=[] # as limited by MAXGROW
flushlen=[] # this is what is provided by budvigour, but not limited by MAXGROW
for n in nodes[4:len(nodes)]: #skip first there nodes as they are set to INITIALNODES
	fl=Feature(n,'FlushLen')
	nc=Feature(n,'NumSegs')
	if fl >0:
		flushlen.append(fl)
		numsegs.append(nc)
stdout.write('Mean actual flush len %.2f %.2f - %.2f (%i) \n' % (mean(numsegs),min(numsegs),max(numsegs),len(numsegs)))
stdout.write('Mean potential        %.2f %.2f - %.2f (%i) \n' % (mean(flushlen),min(flushlen),max(flushlen),len(flushlen)))

nbins=10
set1=array(numsegs)
set2=array(flushlen)
histogram(set1,set2,nbins)
