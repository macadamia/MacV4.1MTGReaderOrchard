# -*- coding: utf-8 -*-
"""
Created on Tue Mar  1 14:35:52 2011
Calculation of Pitch on the fly
from openalea.aml import MTG, VtxList, Feature, Trunk, Location, Father, Order, Sons, Index
from math import sqrt,  degrees, acos
from euclid import *
from numpy import std,  mean

@author: neil
"""

from openalea.aml import MTG, VtxList, Feature, Trunk, Location, Father, Order,  Index
from math import degrees, acos
from euclid import *
from numpy import std,  mean

def xx(x):
	return Feature(x, 'XX')
def yy(x):
	return Feature(x, 'YY')
def zz(x):
	return Feature(x, 'ZZ')
def addDictList(aDict,key,value):
	try:
		l=aDict[key]
		l.append(value)
		aDict[key]=l
	except KeyError:
		aDict[key]=[value]
	return aDict
mfile='ModelMTG.mtg'

m=MTG(mfile)
branches=VtxList(Scale=2)
nodes=VtxList(Scale=3)
pitch={}
branchiness={}
nodesPerFlush={}
tlength={}
vigour={}
pitches=[]
print "pitch (degrees)"
for o in range(0,10):
	nodesPerFlush[o]=[]
for b in branches:
	bnode=Location(b)  # branch point
	if bnode==None:
		continue
	pnode=Father(bnode)
	o=Order(b)
	tlist=Trunk(b)
	if len(tlist)>=3:  # skip short nodes for pitch calc
		try:
			s1=tlist[2] # set to -1 to use Wojciech's chord (terminal) or 0 to use Floradig pitch (+S node) or 1, 2,3,4 to use the  2nd, 3rd, 4th node etc
		except IndexError:
			s1=tlist[-1] # try third node, but fall back to terminal node
		v1=Vector3(xx(pnode),yy(pnode),zz(pnode))
		v2=Vector3(xx(bnode),yy(bnode),zz(bnode))
		v3=Vector3(xx(b),yy(b),zz(b))
		v4=Vector3(xx(s1),yy(s1),zz(s1))
		#Pitch
		vec1=(v2-v1).normalized()
		vec2=(v4-v3).normalized()
		ang=degrees(acos(vec1.dot(vec2)))
		pitch=addDictList(pitch,o,ang)
		if o <= 4 and o >0:
			pitches.append(ang)
for o in range(1,max(pitch.keys())+1):
 try:
 	m=mean(pitch[o])
 	print '%i %.1f' % (o,m)
 except ValueError:
 	print '%i --' % o
print 'Overall 1-4: %.1f' % mean(pitches)
