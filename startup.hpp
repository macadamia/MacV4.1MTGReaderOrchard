Start:
{
	// Set up initial variables
	time(&startsec);
	phase = READ;
	flushno = TREEFLUSH; //tracks the cycles through all stages
	step=0; //derivation step
	age=TREEAGE;
	lambda = INITLAM;
	seed =time(0);
	seed=RSEED;
	srand (seed);
	totSegs=0;


	
	Printf("Steps: %i\n",STEPS);
	sprintf(mtgName,"%s%s",MTGDIR,MTGFILE);
	// Set up the shadow map
	env.setParam(SPREAD,DEPTH,STRENGTH,FADE,Ran,Vert);
	env.initExposureMap();
	for(int t = 0;t<9;t++){
		gICount[t]=0;
		gBCount[t]=0;
		gCalcNodesFlush[t]=0;
		gCalcNodesBranch[t]=0;
		gCalcBranchFlush[t]=0;
		gPredictedVolume[t]=0.0;
		gCalculatedWidth[t]=0.0;
		gCalculatedHeightOfBranches[t]=0.0;
		gCalculatedHeightOfFlush[t]=0.0;
		gCp[t]=0.0;
		gCanopyDepth[t]=0.0;
		idwidth[t]=0.0;
		firstBranch[t]=999999.;
		gLightAtBase[t]=0.0;
	}
	area=( INTERROW * INTERTREE )/100000000.0f;
	tPruned=0;
	PruneFlag=false;

	manPruning=false;
	outsideBox=false;
	doMTG=false;

	for(int i=0;i<7;i++){
		nodeType[i]=0;
	}

	MODELFIT=fopen("ModelFit.csv","w");
	char Tree[64];
	sprintf(Tree,"%s",MTGFILE);
	fprintf(MODELFIT,"Tree,SPREAD,DEPTH,STRENGTH,FADE,DROPTHRESH,INITLAM,TARGLAM,TRANSITION,DELAY,LIGHTFACTOR,INTERROW,INTERTREE,WINTER\n");
	fprintf(MODELFIT,"%s,%.1f,%i,%.1f,%.1f,%.3f,%.1f,%.1f,%i,%i,%.2f,%i,%i,%.1f\n\n",Tree,SPREAD,DEPTH,STRENGTH,FADE,DROPTHRESH,INITLAM,TARGLAM,TRANSITION,DELAY,LIGHTFACTOR,INTERROW,INTERTREE,WINTER);
	fprintf(MODELFIT,"TN,Flushno,CalcHtBranches,CalcHtFlush,Ht,NodeWidth.Pred,NodeWidth.Model,Volume.Pred,Volume.Model,Node.Pred.Branches,Nodes.Pred.Flush,Nodes.Model,Branches.Pred,Branches.Model,LightAtBase,CanopyDepth,MaxHt,MaxWidthX,MaxWidthZ,MaxWidth,firstBranch\n");
	BUDDATA=fopen("BudData.csv","w");
	fprintf(BUDDATA,"Flush,Apical,Lateral,Total\n");
}

StartEach:
{
	step++;
	// Depending on the current phase, we do some simple stuff:
	// 1. BHACCUMULATE and PRUNE are Backward(), the others are Forward()
	// 2. We only draw on phase SET_POSITIONS
	// 3. The flushno number is incremented every time through GROW
	UseGroup(phase);
	switch(phase)
	{
	case READ:
		Printf("READ (%i)\n",step);
		Forward();
		break;
	case ADJUSTWIDTH:
		Printf("Adjusting Widths (%i)\n",step);
		Backward();
		DisplayFrame();
		break;
	case GROW:
		Printf("GROW (%i)\n",step);
		
		flushno++;
		aBudGrew=0;
		aBudFail=0;
		lBudGrew=0;
		lBudFail=0;
		totalBuds=0;
		totalGrew=0;
		totalABuds=0;
		totalLBuds=0;
		percBuds=0;
		percABuds=0;
		percLBuds=0;
		Forward();
		break;

	case INTERPRET_POSITIONS:
		Printf("INTERPRET_POSITIONS (%i)\n",step);
		Forward();
		break;
	case SET_POSITIONS:
		Printf("SET_POSITIONS (%i)\n",step);
		Forward();
		for(int t=0;t<9;t++){
			maxHt[t]=0.; //NW Nov 10
			maxX[t]=-99999.0; //NW Jul 14 Chaged max to large negative
			minX[t]=99999.;
			minZ[t]=99999.;
			maxZ[t]=-99999.0;
			maxWidthX[t]=0.;
			maxWidthZ[t]=0.;
		}
		nPruned=0; //NW Nov 10
		if(doMTG){
			Printf("\nOpening XYZ file\n");
			if(USERANDFNAMES) {
				sprintf(randomstring,"%s",randomString(6).c_str()); //do this once so csv and mtg have the same random name
				sprintf(fname,"ModelXYZ_%s.csv",randomstring);
			}
			else {
				sprintf(fname,"ModelXYZ.csv");
			}
			XYZfile=fopen(fname, "w");
			fprintf(XYZfile, "X,Y,Z,order\n");
	
			Printf("\nOpening MTG file\n");
			if(USERANDFNAMES) {
				sprintf(mname,"ModelMTG_%s.mtg",randomstring);
			} else {
				sprintf(mname,"ModelMTG.mtg");
		}
		MTGfile=fopen(mname, "w");
		createMTG(MTGfile, MTGstack, MTGcurOrder, MTGplantStart, MTGlatStart);
		}
		break;

	case BHACCUMULATE:
		Printf("BHACCUMULATE (%i)\n",step);
		Backward();
		break;
	case BHDISTRIBUTE:
		Printf("BHDISTRIBUTE (%i)\n",step);
		Forward();
		break;

	case PRUNE:
		nPruneCaps=0;
		Printf("PRUNE (%i)\n",step);
		Backward();
		nPruned=0;
		DisplayFrame();
		break;
	case BAIL:
		break;
	}

}

EndEach:
{
	// Simple phase cycle of
	// GROW -> INTERPRET_POSITIONS -> XYZ -> SET_POSITIONS -> BHACCUMULATE -> BHDISTRIBUTE -> PRUNE -> repeat
	switch(phase)
	{
	case READ:
		if(step==1){
			phase=READ;
			Printf("Start READ phase part 2\n");
		}
		else {
			phase=ADJUSTWIDTH;
			Printf("READ phase completed\n\n");
		}
		break;
	case ADJUSTWIDTH:
		Printf("Width Adjust complete\nWidth at base is %.3f cm\n\n",idwidth[TREEOFINTEREST]);
		phase=INTERPRET_POSITIONS;
		DisplayFrame();
		break;
	case GROW:
		if(flushno % 2 == 0 || flushno==0){age++;} 	//age is incremented on odd flushes only, except the first
		if(age<DELAY+TRANSITION) {
		//change in lambda over time.
			if(age>DELAY){
				lambda=((DELAY+TRANSITION-age)*INITLAM + (age-DELAY)*TARGLAM)/TRANSITION;
			} else {lambda=INITLAM;}
		} else {lambda=TARGLAM;}
		Printf("Lambda now %.2f (step %i, age %i)\n\n",lambda,step,age);
		Printf("Nodes %i Branches %i N:B %.1f\n",gICount[TREEOFINTEREST],gBCount[TREEOFINTEREST],gICount[TREEOFINTEREST]/(float)gBCount[TREEOFINTEREST]);
		if(flushno > TREEFLUSH){
			totalBuds=aBudGrew+aBudFail+lBudGrew+lBudFail;
			totalGrew=aBudGrew+lBudGrew;
			totalABuds=aBudGrew+aBudFail;
			totalLBuds=lBudGrew+lBudFail;
			percBuds=totalGrew/totalBuds;
			percABuds=aBudGrew/totalABuds;
			percLBuds=lBudGrew/totalLBuds;
			Printf("\n Flush: %i\nPerc of Buds growing: apical: %.2f lateral: %.2f Total: %.2f\n",flushno,percABuds,percLBuds,percBuds);
			fprintf(BUDDATA,"%i,%f,%f,%f\n",flushno,percABuds,percLBuds,percBuds);
			}
		phase = INTERPRET_POSITIONS;
		break;
	case INTERPRET_POSITIONS:
		doMTG=false;
		if(flushno==XYZFLUSH && flushno>=0){
			doMTG=true;
		}
		phase=SET_POSITIONS;
		break;
	case SET_POSITIONS:
		phase = BHACCUMULATE;
		//NW Nov 10
		Printf("Current height of plant after %i flushes is %.1f cm\n",flushno,maxHt);
		Printf("Pruned %i entities\n",nPruned);
		Printf("End of Growing Flush %i (year %i) (step %i)\n**************\n\n",flushno,age,step);
		if(doMTG){
			fclose(XYZfile);
			Printf("Closed XYZ file\n\n");
			fclose(MTGfile);
			Printf("Closed MTG %s file\n\n",mname);
			Printf("\n Highest nodenum %i\n",highNode);
			doMTG=false;
		}
		if(manPruning){
			manPruning=false;
		}
		
		if(gICount[TREEOFINTEREST] > 25000){
			Printf("Bailing out. Node count too high: %i\n",gICount[TREEOFINTEREST]);
			phase=BAIL;
		}
		
		if(flushno>=7){
			for(int t=0;t<9;t++){
				maxWidth[t]=max(maxWidthX[t],maxWidthZ[t]);
				gCanopyDepth[t] = maxHt[t]*0.01-firstBranch[t]*0.01;
				gCp[t]=PI*((pow(maxWidth[t]*0.01,2)*(gCanopyDepth[t]))/8.0)/area;  //converted from cm^3 to m^3/ha
				//Ellipsoid from McFadyen 2004 doesn't work so well as we only use canopy height
				//gCp[t]=((PI*maxWidthX[t]*maxWidthZ[t]*maxHt[t])/6.0f)/area;
				gCalcNodesFlush[t]=int(1.004f*pow(float(flushno),3.684f));
	
				gCalcBranchFlush[t]=0.2641*pow((float)flushno,3.361f);
				gCalcNodesBranch[t]=int(8.429f*gBCount[t]);
				
				gPredictedVolume[t]=0.214*pow(gCanopyDepth[t],3.4693f)/area; // m^3/ha
				gCalculatedWidth[t]=0.03*maxHt[t]-2.06;
				gCalculatedHeightOfFlush[t]=33.981*flushno-0.6726;
				gCalculatedHeightOfBranches[t]=5.5416*gBCount[t]-3.634;
			}
			
			if(gCalcNodesFlush[TREEOFINTEREST ]> 1.5*gICount[TREEOFINTEREST] && Condor){
				Printf("bailing because of too few nodes. Created %i, should be %i\n",gICount,gCalcNodesFlush);
				phase=BAIL;
			}
			if(gCalcBranchFlush[TREEOFINTEREST]> 1.5 * gBCount[TREEOFINTEREST] && Condor){
				Printf("bailing because of too few branches. Created %i, should be %i\n",gBCount,gCalcBranchFlush);
				phase=BAIL;
			}
			if(gCalculatedHeightOfFlush[TREEOFINTEREST]> 1.5 * maxHt[TREEOFINTEREST]&& Condor){
				Printf("bailing because too short. Grew to %.1f, should be %.1f\n",maxHt,gCalculatedHeightOfFlush);
				phase=BAIL;
			}
			if(gCalcNodesFlush[TREEOFINTEREST]* 1.5 < gICount[TREEOFINTEREST]&& Condor){
				Printf("bailing because of too many nodes created %i, should be %i\n",gICount,gCalcNodesFlush);
				phase=BAIL;
			}
			if(gCalcBranchFlush[TREEOFINTEREST]* 1.5 < gBCount[TREEOFINTEREST]&& Condor){
				Printf("Bailing because of too many branches. Created %i, should be %i\n",gBCount,gCalcBranchFlush);
				phase=BAIL;
			}
			if(gCalculatedHeightOfFlush[TREEOFINTEREST]* 1.5 <  maxHt[TREEOFINTEREST]&& Condor){
				Printf("bailing because  too tall. Grew to %.1f, should be %.1f\n",maxHt,gCalculatedHeightOfFlush);
				phase=BAIL;
			}
			if( (gPredictedVolume[TREEOFINTEREST]> gCp[TREEOFINTEREST]*1.5 || gPredictedVolume[TREEOFINTEREST]< gCp[TREEOFINTEREST]*0.6667 ) && flushno > 10 && Condor){
				Printf("Expected volume was %.1f, got %.1f instead\n",gPredictedVolume,gCp);
				phase=BAIL;
			}
			if(outsideBox && Condor){
				Printf("bailing because outside box\n");
				phase=BAIL;
			}
			
			for(int t = 0;t <9;t++){
				fprintf(MODELFIT,"%i,%i,%f,%f,%f,%f,%f,%f,%f,%i,%i,%i,%i,%i,%f,%f,%f,%f,%f,%f,%f\n",t,flushno,gCalculatedHeightOfBranches[t], gCalculatedHeightOfFlush[t], maxHt[t],gCalculatedWidth[t],idwidth[t],gPredictedVolume[t],gCp[t],gCalcNodesBranch[t],gCalcNodesFlush[t],gICount[t],gCalcBranchFlush[t],gBCount[t],gLightAtBase[t],gCanopyDepth[t],maxHt[t],maxWidthX[t],maxWidthZ[t],maxWidth[t],firstBranch[t]);
			}
		}
		
		break;

	case BHACCUMULATE:
		phase = BHDISTRIBUTE;
		break;
	case BHDISTRIBUTE:
		if(step ==6)
			phase = GROW;
		else
			phase = PRUNE;
		break;

	case PRUNE:
		phase = GROW;
		Printf("Produced %i PruneCaps\n",nPruneCaps);
		break;
	case BAIL:
		break;
	}
}

End:{ //NW Nov 10
	Printf("\nTotal Pruned %i\n",tPruned);
	Printf("Max height of plant after %i flushes is %.1f cm\n",flushno,maxHt[TREEOFINTEREST]);
	Printf("Height:Width %.1f\n",maxHt[TREEOFINTEREST]/max(maxWidthX[TREEOFINTEREST],maxWidthZ[TREEOFINTEREST]));
	Printf("Max Width of Canopy (cm) %.1f\n",max(maxWidthX[TREEOFINTEREST],maxWidthZ[TREEOFINTEREST]));
	Printf("Ratio of X:Z widths %.3f (%3f %3f) \n",maxWidthX[TREEOFINTEREST]/maxWidthZ[TREEOFINTEREST],maxWidthX[TREEOFINTEREST],maxWidthZ[TREEOFINTEREST]);
	Printf("Final Lambda %.2f\n\n",lambda);
	Printf("Nodes %i Branches %i N:B %.1f\n",gICount[TREEOFINTEREST],gBCount[TREEOFINTEREST],gICount[TREEOFINTEREST]/(float)gBCount[TREEOFINTEREST]);
	Printf("Total production of Nodes %i\n",totSegs);
	Printf("Width of base of main stem is %.2f\n",idwidth[TREEOFINTEREST]);
	if(outsideBox){
		Printf("\n*********************************\n");
		Printf("	 Warning: Tree Exceeded Light Model\n");
		Printf("\n*********************************\n");
	}
	Printf("\n**************\nEnd of simulation (%i steps)\n\n",step);
	time(&endsec);

	difsec=difftime(endsec,startsec);

	if(difsec > 60.0)
		Printf("It took %.4f minutes\n\n",difsec/60.0f);
	else
		Printf("It took %.4f seconds\n\n",difsec);
	Printf("\n Random Number Seed: %i\n\n",seed);
	srand (seed);
	Printf("\n Highest nodenum %i\n",highNode);
	fclose(MODELFIT);
	fclose(BUDDATA);
}