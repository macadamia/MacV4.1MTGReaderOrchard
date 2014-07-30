from sys import argv,stdout,stdin
from openalea.aml import MTG, VtxList

#get mtg file name
#mfile=argv[1]
mfile='ModelMTG.mtg'

m=MTG(mfile)
branches=VtxList(Scale=2)
nodes=VtxList(Scale=3)
ln=len(nodes)
lb=len(branches)
rat= ln / float(lb)
stdout.write("Nodes %i  Branches %i\n" % (ln,lb))
stdout.write('\nNode:Branch ratio is %.2f\n' % (rat))
