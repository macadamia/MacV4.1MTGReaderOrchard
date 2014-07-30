from sys import argv,stdout,stdin
from openalea.aml import MTG, VtxList, Trunk, Feature
from openalea.core.alea import load_package_manager, function
from numpy import mean, array

pm = load_package_manager()
nf = pm['__my package__']['mtgcomp']
disp = function(nf)

mfile='ModelMTG.mtg'
disp(mfile)
