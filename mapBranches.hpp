//MTG reader
//uses a mixture of C++ and Python/OpenAlea


map<int,int> nbranches; //number of exiting branches at this nodenum
map<int,int> Descend; //the last node for all Descendants of a node
map<int,int> nodesPerAxis; //number of nodes in axis starting at nodenum defined by Location of branch
map<int,int>::iterator it;
map<int,int> ParentOfNode; // node number and its parent
map<int,int> LastNodeOfAxis;// last node numder of an Axis starting at Sx
map<int,V3f> sxXYZ;// XYZ of of the parent of a Sx
map<int,int> sbeb; //ckeep idea of open and closed branches
char mtgName [512];
int xN,yN,zN,widthN,lenN,typeN,nodeN, levelN; //where these data can be found
int mapBranches (V3f pos)
{
	string sline;
	int axis,nn, ln, descend;
	//for the python section to get axis lengths
	FILE *fp;
	char line[256];
	//
	ifstream mtg; // file containg the details for bulding the Lsystem
	bool foundStart;
	char * cstr, *pch;
	int retValue=1;
	int nodenum, curBranch,nb,curOrder;
	float bx,by,bz;
	int loc;
	int branchLevel [10]; //keeps track of the branch level we are on
	for(int i=0;i<10;i++){
		branchLevel[i]=0;
	}
	foundStart=false;
	mtg.open(mtgName, ifstream::in);
		if(mtg.good()){
		Printf("all good with %s in mapBranches\n",mtgName);
	} else {
		Printf("%s NOT good in mapBranches ", mtgName);
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
	/*use python to create nbranches.txt which is a list of nodes for S types and the length of the axis*/
	char cmdLine[256];
	
	sprintf(cmdLine,"%s combined.py %s",PYTHON,mtgName);
	#ifdef _MSC_VER
		fp = _popen(cmdLine, "r");
	#else
		fp = popen(cmdLine, "r");
	#endif
	while ( fgets( line, sizeof line, fp))
	{
		Printf("%s", line);
  }
  #ifdef _MSC_VER
	_pclose(fp);
  #else
	pclose(fp);
  #endif
  	
	fp=fopen("nbranches.txt","r");
	while (fscanf(fp,"%i %i %i", &axis, &loc, &nn) != EOF) {
		//fprintf(stdout,"%i %i\n",axis,nn);
		nodesPerAxis[axis]=nn;
	}
	fclose(fp);

	fp=fopen("parents.txt","r");
	while (fscanf(fp,"%i %i", &nn, &axis) != EOF) {
		ParentOfNode[nn]=axis;
	}
	fclose(fp);

	fp=fopen("lastNodes.txt","r");
	while (fscanf(fp,"%i %i %i", &axis, &ln, &nb) != EOF) {
		//check=LastNodeOfAxis.find(axis)  -> second;
		//if(check==0)
			LastNodeOfAxis[axis]=ln;
	}
	fclose(fp);

	fp=fopen("branchXYZ.txt","r");
	while (fscanf(fp,"%i %i %f %f %f", &axis, &loc, &bx, &by, &bz) != EOF) {
		sxXYZ[loc]=V3f(bx+pos.x,by+pos.y,bz+pos.z);
		//Printf("%i %.2f %.2f %.2f\n",axis,bx,by,bz);
	}
	fclose(fp);
	
  /*----------------------------------*/
	while (!mtg.eof() && mtg.good() ){
		getline(mtg,sline);
		if(foundStart){
			cstr = new char [sline.size()+1];
			if(foundStart){
				strcpy (cstr, sline.c_str());
				pch = strtok (cstr,"\t");
				int ic=1;
				while (pch != NULL) {
					pch = strtok (NULL, "\t");
					if(pch!= NULL)
						if(ic==nodeN){nodenum=atoi(pch);}
						if(ic==levelN){curOrder=atoi(pch)-1;}
						ic++;
					}
				}
			if(sline.find("P1") != -1){ // start of plant
				//get the current branch node number
				// and store this so it can be used to map branches from this point
				curBranch=nodenum;
				
			}
			if(sline.find("^/N") != -1 ) {
				curBranch=branchLevel[curOrder-1];
				nb=nbranches.find(curBranch)->second;
				nb++;
				nbranches[curBranch]=nb;
//				if(curBranch==27)
//					Printf("Branch %i at %i ^/N= %i\n",nb,curBranch,nodenum);
			}
			if(sline.find("^<N") != -1 ) {
				branchLevel[curOrder]=nodenum;
			}
		} else { // !foundStart
			
			//Printf("%s\n",sline.c_str());
			if((int)sline.find("ENTITY-CODE") != -1){
				foundStart=true;
				Printf("Found start of data\n");
				//workout the column numbers for the entities
				cstr = new char [sline.size()+1];
	  		strcpy (cstr, sline.c_str());
	  		pch = strtok (cstr,"\t");
	  			
				xN=0;
				yN=0;
				zN=0;
				widthN=0;
				lenN=0;
				typeN=0;
				nodeN=0;
				levelN=0; //order
				char test[10];
				int ic=1;
	  			while (pch != NULL)
	  			{
	    			pch = strtok (NULL, "\t");
						if(pch != NULL) {
							sprintf(test,"%s",pch);
							//Printf("%s| %s: %i\n",test,pch,ic);
							if(strcmp("XX",test) ==0) {xN=ic;}
							if(strcmp("YY",test) ==0){yN=ic;}
							if(strcmp("ZZ",test) ==0){zN=ic;}
							if(strcmp("TopDia",test) ==0){widthN=ic;}
							if(strcmp("ILength",test) ==0){lenN=ic;}
							if(strcmp("NType",test) ==0){typeN=ic;}
							if(strcmp("Node",test) ==0){nodeN=ic;}
							if(strcmp("Level",test) ==0){levelN=ic;}
							ic++;
						}
	  			}
	  			Printf("Test we have all the data\n");
				if( xN==0 || yN==0 || zN==0 || widthN==0 || lenN==0 || typeN==0 || nodeN==0 || levelN==0){
					Printf("Not all of the the required features were found\n");
					Printf("%i %i %i %i %i %i %i %i \n",xN,yN,zN,widthN,lenN,typeN,nodeN, levelN);
					retValue=1;
				} else {
					Printf("Found all the bits we want\n");
					Printf("%i %i %i %i %i %i %i %i \n",xN,yN,zN,widthN,lenN,typeN,nodeN, levelN);
					retValue=0;
				}
			}
		}
		
	}
	
	Printf("Finished with ret = %i\n\n",retValue);
	mtg.close();
  return retValue;
}

