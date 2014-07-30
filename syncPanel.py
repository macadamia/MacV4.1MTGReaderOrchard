from sys import argv,stdout
from os import path
from shutil import copy
from os import unlink

def ncr(s):
    return s.split('\n')[0]

try:
    srcfile=path.split(argv[0])[1]
except IndexError:
    srcfile='thisfile'
try:
    pnlfile=argv[1]
except IndexError:
    pnlfile='simple.pnl'
try:
    incfile=argv[2]
except IndexError:
    incfile='parameters.inc'

pnl=file(pnlfile,'r')
tmp=file('tmppanel.pnl','w')
inc=file(incfile,'r')
pnlDict={}
infileDict={}

#read pnl and get list of variables
newpnl=False
readItems=False
defines={}

#crfeate deictionary of defines and their values
while True:
    line=inc.readline()
    if not line:
        break
    if line=='\n':
        continue
    sline=line.split()
    defines[sline[1]]=sline[2]
inc.close()
updateRequired=False
while True:
    line=pnl.readline()
    if not line:
        break
    if line.find('pver')==-1:
        break
    #read details of this file
    tmp.write(line) # pver
    line=pnl.readline()
    tmp.write(line)# name
    line=pnl.readline()
    tmp.write(line)#associate
    line=pnl.readline()
    tmp.write(line)#trigger
    items=int(ncr(pnl.readline().split('items: ')[1]))
    tmp.write('items: %i\n' % (items))
    for i in range(0,items):
        line=pnl.readline()
        ptype=line.split('type: ')[1]
        tmp.write(line)#type
        if ptype.find('SLIDER')<>-1:
            line=pnl.readline()
            tmp.write(line)# name
            line=pnl.readline()
            tmp.write(line)# colors
            line=pnl.readline()
            tmp.write(line)# origin
            line=pnl.readline()
            tmp.write(line)# min/max
            vline=pnl.readline() # value line and check if it has changed
            value=int(vline.split('value: ')[1])
            mline=pnl.readline()
            sline=mline.split()
            pname=sline[2]#take parameter name from message
            scale=int(sline[4])
            try:
                newvalue=int(defines[pname])*scale
            except ValueError: #must be a float
                newvalue=int(float(defines[pname])*scale)
            if value<>newvalue:
		updateRequired=True
                print 'updating value for %s from %i to %i' % (pname,value,newvalue)
                tmp.write('value: %i\n' % (newvalue))
            else:
                tmp.write(vline)
            tmp.write(mline)#message
        if ptype.find('LABEL')<>-1:
            line=pnl.readline()
            tmp.write(line)# name
            line=pnl.readline()
            tmp.write(line)# color
            line=pnl.readline()
            tmp.write(line)# origin
        tmp.write('\n')
        cr=pnl.readline()
pnl.close()
tmp.close()
if updateRequired:
	#copy pnlfile to old
	copy(pnlfile,pnlfile+'.old')
	#copy tmp to pnlfile
	copy('tmppanel.pnl',pnlfile)
unlink('tmppanel.pnl')

