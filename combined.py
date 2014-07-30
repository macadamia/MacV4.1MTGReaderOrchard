#outputs branch location, location, length of branch and last node of it's descendants
import sys
def analysis(mtgfile):
	import openalea.aml as aml
	mtg=aml.MTG(mtgfile)
	branches = aml.VtxList(Scale=2)
	alist=[]
	nbranchestxt=file('nbranches.txt','w')
	branchXYZtxt=file('branchXYZ.txt','w')
	lastNodestxt=file('lastNodes.txt','w')
	parentstxt=file('parents.txt','w')
	for b in branches:
		#where is the branch located
		ln=aml.Axis(b,Scale=3)[-1]
		if aml.Order(b) > 0:
			nb=len(aml.Sons(aml.Location(b-1)))
		else:
			nb=0
		lastNodestxt.write( "%i %i %i\n" % (b,ln,nb))
		if b > 2:
			loc=aml.Location(b) # this is a node
			#length of branch
			x=aml.Feature(loc,'YY')
			y=aml.Feature(loc,'ZZ')
			z=aml.Feature(loc,'XX')
			branchXYZtxt.write( "%i %i %.2f %.2f %.2f\n" % (b,loc,x/10.,y/10.,z/10.))
			blen=len(aml.Trunk(b))
			nbranchestxt.write('%i %i %i \n' % (b+1,loc,blen))
	print 'Created nbranches and branchXYZ and some of lastNodes on lab table'
	print
	nodes=aml.VtxList(Scale=3)
	print 'Processing parents and rest of lastNodes for each of %i nodes' % len(nodes)
	for n in nodes:
		if aml.Order(n) > 0:
			axis=aml.Location(aml.Axis(n,Scale=2)[0])
			parentstxt.write( "%i %i\n" % (n,axis))
		ln=aml.Descendants(n)[-1]
		lastNodestxt.write( "%i %i 0\n" % (n,ln))
		nbranchestxt.close()
	branchXYZtxt.close()
	parentstxt.close()
	lastNodestxt.close()
	print '**********Finished processing**********'

if __name__=="__main__":
    analysis(sys.argv[1])
