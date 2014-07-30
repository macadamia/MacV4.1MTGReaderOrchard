TreeReader(pos,tn, rn, pn):
{
	//char line[256];
	minx[tn]=999999.;
	miny[tn]=999999.;
	minz[tn]=999999.;
	maxx[tn]=-999999.;
	maxy[tn]=-999999.;
	maxz[tn]=-999999.;
	Printf("Running TreeReader for plant %i\n");
	string sline,segments, keep;
	vector<string> v2;
	stringstream ss;
	bool foundStart;
	char * cstr, *pch;
	FILE *fp;
	int retValue;
	foundStart=false;
	ifstream mtg; // file containg the details for bulding the Lsystem
	int tmp;
	int curOrder, prevOrder; //order for where we are in the read
	int curNode;
	int curLevel; //like curOrder, but somethimes this???
	int linesRead=0;
	int npos, spos, keepNode;
	int node, snode, nodenum,thisBranch;
	int nb, nn, maxOrder;
	nb=0;
	nn=0;
	int theParent, nNodes,axis;
	int branchLevel [10]; //keeps track of the branch level we are on
	for(int i=0;i<10;i++){
		branchLevel[i]=-1;
	}
	//V3f XYZ; //helps keep track of XYZ of an unfinished branch
	V3f branchXYZ [10];
	for(int i=0;i<10;i++){
		branchXYZ[i]=V3f(0,0,0);
	}
	float x,y,z,w,l; //node XYZ, width and length
	float px,py,pz;
	V3f sp,ep,u,h,dir;
	int nt; //nodetype
	float activity; //buds
	h=V3f(0,1.,0); //initial heading and up vector
	u=V3f(0,0,1.);
	Qf q;
	InternodeData newInternode(false);
	
	retValue=mapBranches(pos);
	if(retValue==1){
		Printf("\n***********\n mapBranches failed\n**********\n");
	} else {
		Printf("back from mapBranches, on with the show for tree %i\n",tn);
	}
	
	maxOrder=-1;
	curOrder=-1;
	nodenum=0;
	Printf("loop until ENTITY-CODE line is found, top of actual data \n");
	mtg.open(mtgName, ifstream::in);
	if(mtg.good()){
		Printf("all good with %s\n",mtgName);
	} else {
		Printf("%s NOT good ", mtgName);
		if(mtg.fail()){
			Printf("it failed\n");
		}
		if(mtg.eof()){
			Printf("it eof\n");
		}
		if(mtg.bad()){
			Printf("it bad\n");
		}
	}
	while (!mtg.eof() && mtg.good()){

		getline(mtg,sline);
		if(sline.size() ==0 && foundStart){
			Printf("Short Line is size %i - exit MTG reading loop\n",sline.size());
			break;
		}
		cstr = new char [sline.size()+1];
		if(foundStart){
		// Found start of data extract data from current line
	  	strcpy (cstr, sline.c_str());
	  	pch = strtok (cstr,"\t");
	  	int ic=1;
			do {
				pch = strtok (NULL, "\t");
				if(pch!= NULL){
					//if(SHOWB)
					//	Printf("%s ",pch);
					//switch x,y,z from MTG order to VLAB order
					if(ic==xN){
						z=atof(pch)/10.+pos.z;
						minz[tn]=min(minz[tn],z);
						maxz[tn]=max(maxz[tn],z);
						maxWidthZ[tn]=max(maxWidthZ[tn],(maxz[tn]-minz[tn]));
					} //convert from mm to cm
					if(ic==yN){
						x=atof(pch)/10.+pos.x;
						minx[tn]=min(minx[tn],x);
						maxx[tn]=max(maxx[tn],x);
						maxWidthX[tn]=max(maxWidthX[tn],(maxx[tn]-minx[tn]));
					}
					if(ic==zN){
						y=atof(pch)/10.+pos.y;
						miny[tn]=min(miny[tn],y);
						maxy[tn]=max(maxy[tn],y);
					}
					if(ic==widthN){w=atof(pch)/10.;}
					if(ic==lenN){l=atof(pch)/10.;}
					if(ic==typeN){nt=atoi(pch);}
					if(ic==nodeN){nodenum=atoi(pch);}
					if(ic==levelN){curOrder=atoi(pch)-1;}
					//Printf("%.2f %.2f %.2f\n",z,x,y);
					ic++;
				}
			} while (pch != NULL);
			//if(SHOWB)
				//Printf("\n");
			
			//store line in pieces in ss, split by tab
			ss << sline;
			while(getline(ss,segments,'\t')){
				v2.push_back(segments);
			}
			ss.clear();
			for(int j=0;j<v2.size();j++){
				if(v2[j].size()>1){
					keep = v2[j];
					break;
				}
			}
			//extract node number
			size_t lastBitOfEntity;
			lastBitOfEntity = keep.find_last_of("SNL");
			keepNode = atoi(keep.substr(lastBitOfEntity+1).c_str());
			
			if(sline.find("+L") != -1 || sline.find("+S") != -1  ){;
				if(curOrder<prevOrder){
					for(int o=curOrder;o<prevOrder;o++){
						if(branchLevel[o] != -1){
							if(SHOWB){Printf("*+L or +S * Closing branch for %i at node %i (+S%i)\n",branchLevel[o],nodenum,keepNode);}
							nproduce EB;
							branchLevel[curOrder]=-1;
						}
					}
				}
				curOrder=prevOrder;
				//Printf("L or S -> next line\n");
				continue;
			}
			
			
			v2.clear();
			linesRead++;
 			if(nodenum>NODESTOREAD){ //early escape
 				Printf("Read to node %i\n",NODESTOREAD);
 				Printf("Branchlevel\n");
				for(int i=0;i<10;i++){
					Printf("%i ",branchLevel[i]);
				}
				Printf("\n");
 				break;
 			}
			if(curOrder > maxOrder){
		    		maxOrder=curOrder;
			}

			/*    Start of Plant          */
			if(sline.find("P1") != -1){ // start of plant
				x=pos.x;//0.0;
				y=pos.y;//0.0;
				z=pos.z;//0.0;
				sp=pos;//V3f(x,y,z);
				curNode=0;
				curOrder=0;
				prevOrder=0;
				// Roots define the base of the tree, ignoring the first set of main stem internodes
				if(SHOWB){Printf("nproduce Roots\n");}
				nproduce Roots(pos,tn,rn,pn);
				continue;
			} //P1
			/*    End of Plant          */

			InternodeData newInternode(false); //create a new internode
			newInternode.tn=tn;
			newInternode.rn=rn;
			newInternode.pn=pn;
			/*  Deal With Nodes   */
			if(sline.find("^/N") != -1){
				// this is a first node, start a branch, if not main stem\
				//this should be the only reason to start a branch
				nb++;
				nn++;
				if(curOrder >0){
					sp=sxXYZ[ParentOfNode[nodenum]];
					if(SHOWB){
						Printf("SB @ %i MoveTo(%.2f %.2f %.2f) of %i \n",nodenum,sp.z*10.,sp.x*10.,sp.y*10.,ParentOfNode[nodenum]);}
					nproduce SB MoveTo3f(sp);  // move to the node that starts the branch
					branchXYZ[curOrder]=sp; //store this in case we need to go back to it
					newInternode.lateral=true; //a lateral
					branchLevel[curOrder]=nodenum;
				} else {
					newInternode.lateral=false; //a main stem
				}
			} //^/N
			
			if(sline.find("^<N") != -1){
				// this is a some other node
				nn++;
				//if(nodenum==92)
				//	Printf("\n");Printf("\nPrev %i Cur %i\n",prevOrder,curOrder);
				if(prevOrder-curOrder > 1){
					//don't close curOrder or prevOrder, but do close those in between
					//for(int i=0;i<10;i++){
					//	Printf("%i ",branchLevel[i]);
					//}
					//Printf("\n");
					for(int o=curOrder+1;o<=prevOrder;o++){
						//Printf("Order %i bl %i\n",o,branchLevel[o]);
						if(branchLevel[o] != -1){
							if(SHOWB){Printf("* Drop back * Closing Branch %i for Order %i @ %i\n",branchLevel[o],o,nodenum);}
							branchLevel[o]=-1;
							if(SHOWBALLS){nproduce SB SetColor(41) Sphere(1.) EB;}
							nproduce Bud(BudData(nodenum,o,0,0,false,1.0,tn,rn,pn)) EB;
						}
					}
					//for(int i=0;i<10;i++){
					//	Printf("%i ",branchLevel[i]);
					//}
					//Printf("\n");
				}
				
				newInternode.lateral=false; //not a lateral
				//but wait, perhaps I need to restore myself to the start of the previous branch
				if(curOrder<prevOrder){
					//continuation of previous branch
					if(branchLevel[curOrder] != -1 || curOrder==0){
						sp=branchXYZ[curOrder];
						if(SHOWB){Printf("%i MoveTo (%.2f %.2f %.2f) \n",nodenum, sp.z*10.,sp.x*10.,sp.y*10.);}
						nproduce MoveTo3f(sp);
					}		
				}
				branchXYZ[curOrder]=V3f(x,y,z); //used to restore the position
			} //^<N
			
			// produce the node with common attributes
			newInternode.newInternode=true;
			newInternode.nodenum=nodenum;
			w=0.2;  //all widths set to minimum first, this howthe MacV4.1 models start out
			newInternode.width=w; //should be = w; i.e. width	//although it's only for aesthetics
			newInternode.node=keepNode; //node number within branch
			newInternode.order=curOrder;
			activity=1.0;
			newInternode.isLeaf=true;
			newInternode.c=17;
			if(nt==0 || nt==5){
				//newInternode.c=16;
				newInternode.isLeaf=false;  //leaves not present at these sorts of nodes
				activity=0.0;
			}
			
			ep=V3f(x,y,z); //node extends from last point (sp) to this point
			if(SHOWBALLS){
				if(sline.find("^/N") != -1 ){
					nproduce SB SetColor(1) Sphere(1.) EB;
				} else {
					nproduce SB SetColor(tn+2) Sphere(1.) EB;	
				}
			}
			newInternode.length=dist3f(sp,ep); //althought it's in the MTG we need to judge it from the previous node, not the redigitisation of +S

			dir=ep-sp;
			dir.Normalize();
			q=rotateTo(h,dir); // the quaternion specifiying the rotation from current to new vector
			h=q.rotateVector(h); //rotate heading by this amount
			u=q.rotateVector(u); //same for up, L takes care of itself as it the crossproduct of h & u
			u=(axisAngle(h,0.0f)*q).rotateVector(u);
			if(SHOWB){Printf("SetHead I @ %i Length %.2f\n",nodenum,newInternode.length);}
			nproduce SetHead(h.x,h.y,h.z,u.x,u.y,u.z) Internode(newInternode);
			
			//now deal with leaves and Buds
			activity=0.; //turn all buds off unless the apex
			if (LastNodeOfAxis[nodenum]==nodenum) {activity=1.0;} 	// set apical dominance via activity
			vector<int> v = getInitVector(WHORLSIZE); //Randomise the whorl bud number
			
			float leafsize=LEAFSCALE; 
			if(curOrder > 0){
				int budCount=0;
				//the older part of the branch are less likely to have all three leaves
				int makeLeaf = 0;
				int iRand = rand() % 100 + 1; //random number from 1 to 100
				//
				if(newInternode.node >4)
					makeLeaf=WHORLSIZE; // make all leaves if isLeaf
				else { // if earlier nodes reduce the Pr that it will have all three leaves
					if(iRand < 10)
						makeLeaf=1;
					if(iRand > 50)
						makeLeaf=2;
					if(iRand >= 10 && iRand < 50)
						makeLeaf=3;
				}
				for(int w = 0 ; w < WHORLSIZE ; w++){
					if(newInternode.isLeaf && w < makeLeaf){
						float p=LEAFANGLE;
						nproduce SB RollL(WHORLANGLE) Down(p) Leaf(LeafData(newInternode.node,curOrder,w,p,leafsize)) EB;
					}
					int nbh=nbranches.find(keepNode)->second; //number of branches at this branch point
					if(budCount < WHORLSIZE*BUDSINAXIL-nbh){ //skip buds that have already grown into a branch
						for(int bw=1;bw<=BUDSINAXIL;bw++){
							nproduce SB Down(BRANCHANGLE+((bw-1)*10.)) Bud(BudData(keepNode,curOrder,v[w],bw,true,activity,tn,rn,pn)) EB ; //nodenum
						}
						budCount++;
					}
					nproduce RollL(WHORLANGLE);
				}
			} //curOrder >0, don't do this for main stem
			//end of a branch?
			if(LastNodeOfAxis[nodenum]==nodenum && branchLevel[curOrder] != -1){
				if(SHOWB){Printf("End of Branch EB @ %i == %i for %i\n",nodenum,LastNodeOfAxis[nodenum],branchLevel[curOrder]);}
				branchLevel[curOrder]=-1;
				if(SHOWBALLS){nproduce SB SetColor(41) Sphere(1.) EB;}
				nproduce Bud(BudData(nodenum,curOrder,0,0,false,1.0,tn,rn,pn)) EB ; //nodenum EB;
			}
			
			//is this end of the branch set?
			if(prevOrder-curOrder == 1){
				int p=nodenum;
				int nm=nodenum;
				tmp=0;
				do {
					p=ParentOfNode.find(nm) -> second;
					nm=p;
					tmp++;
					if(p>0)
						theParent=p;
					for(int i=0;i<10;i++){
						if(LastNodeOfAxis[branchLevel[i]] == nodenum){
							if(SHOWB){Printf("End of Descendants EB @ %i for %i\n",nodenum,branchLevel[i]);}
							branchLevel[i]= -1;
							if(SHOWBALLS){nproduce SB SetColor(41) Sphere(1.) EB;}
							nproduce Bud(BudData(nodenum,i,0,0,false,1.0,tn,rn,pn)) EB;
						}
					}
				} while (p !=0 && tmp <5);
			}
			
			/*  End of Node Stuff   */
			px=x;
			py=y;
			pz=z;
			sp=ep;
			highNode=nodenum;
			prevOrder=curOrder;
		} else {  //if we haven't found the start, keep looking
			if(sline.find("ENTITY-CODE") != -1 && !foundStart){
				Printf("OK, next line will have plant structure\n");
				foundStart=true;
				prevOrder=0;
				linesRead=0;
				continue;
			}
		}
	} //while (!mtg.eof() && mtg.good())
	for(int i=1;i<10;i++){ //order 0 doesn't start with a SB
		if(branchLevel[i] > 0 ){
			theParent=branchLevel[i];
			branchLevel[i]=-1;
			if(SHOWB){	Printf("Final EB for branch %i order %i \n",theParent,i);}
			nproduce Bud(BudData(0,i,0,0,false,1.0,tn,rn,pn)) EB; //we don't know the nodenum of the parent we are closing
		}
	}
	Printf("\n");
	mtg.close();
	lastNodeRead=highNode; //store this for later

//need to add Parab stuff back in
	//Printf("MTG had %i Nodes and %i Branches N:B %.1f\n",nn,nb,nn/(float)nb);
	Printf("Finished Processing plant %i\n********************\n",tn);
	gICount[tn]=nn;
	gBCount[tn]=nb;
	produce;
}