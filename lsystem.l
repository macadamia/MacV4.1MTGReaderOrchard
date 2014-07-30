#include "lpfgall.h"
#include <stdio.h> 
#include <string.h>
#include <time.h>
#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#ifdef _MSC_VER
	#include <float.h>
#endif
// for dictionay type stuff
#include <map>

using namespace std;
using std::max;
using std::min;

#include "env.hpp"
#include "parameters.inc"
#include "extra.hpp"
#include "quaternion.hpp"
#include "datastruc.inc"
#include "mapBranches.hpp"
#include "MTGWriter.hpp"

#ifdef _MSC_VER
bool isThisNAN(float px){
	return _isnan(px);
}
#else
bool isThisNAN(float px){
	return isnan(px);
}
#endif


/* modules */
module Orchard(int, int);
module TreeReader(V3f,int,int, int);			// Reads the MTG
//module Seed();				// Initial module -- immediately replaced by roots and shoot
module Roots(V3f,int,int, int);				// Represents roots -- merely a marker of the bottom of the string at this point
module Internode(InternodeData);	// An internode
module Bud(BudData);	
module PruneCap(float);			// Represents a pruned branch's width so the pipe model doesn't shrink branches
module Leaf(LeafData);			// Leaf NW 20 June 2011


module Parab(V3f,float, float); //Paraboloid canopy  Starting location, width, height

module Box(bool); //draws a box around the lightmodel // NW Nov 10

/* Ignore rotations, Cut (for pruning), SetTropismDirection3f (for tropisms) */
ignore: Left Right RotateXYZ RotateHLU RollL RollR Up Down SetTropismDirection3f SetHead MoveTo3f;

/* Phases */
#define READ 0				// Reads the preexisting Structure
#define ADJUSTWIDTH 1 // widths are generally missing this will adjust the width from the main stem upwards
#define GROW 2				// Develops the structure
#define INTERPRET_POSITIONS 3		// Place GetPos after every module
#define SET_POSITIONS 4			// Interpret the GetPos and use the location-specific data to update the shadow map
#define BHACCUMULATE 5			// Compute light at each bud and accumulate to the base, computing BH "demand" parameter
#define BHDISTRIBUTE 6			// Distribute vigor to each bud, allocating using "demand" parameter
#define PRUNE 7				// Prune branches with too little vigor (from the outside in)
#define BAIL 8

// NW Nov 10
float maxHt[9]; //max height of tree at end of SET_POSITIONS
float minZ[9], maxZ[9], minX[9], maxX[9], maxWidth[9], maxWidthZ[9], maxWidthX[9]; //to get the width of the canopy and the ellipticalness
float gLightAtBase[9];
//NW Aug 2012
V3f Location; //coordinates of first branching point
float firstBranch[9] ; //height of first branch point
float miny[9], maxy[9], minx[9],maxx[9],minz[9],maxz[9]; // for sensors
float idwidth[9]; // width of first node on main stem of TREEOFINTEREST
int nPruned; // number of entities pruned during PRUNE step
int tPruned; // total entities pruned over the simulation

//number of apical or lateral buds that grew
int aBudGrew, aBudFail;
int lBudGrew, lBudFail;
float totalBuds, totalGrew, totalABuds, totalLBuds, percBuds, percABuds, percLBuds;

//set by MouseInsPos
bool manPruning;

float gModelDim=MODELSIZE/2.0f;
// NW Nov 10 for drawing the box
int X[4]={gModelDim,gModelDim,-gModelDim,-gModelDim};
int Z[4]={-gModelDim,gModelDim,gModelDim,-gModelDim};
bool outsideBox; // warning that the tree grew outsize the LightModel

LightModel env(DENSITY,gModelDim);	//Creating an instance of the LightModel class

int seed; //for random numbers
int flushno, step, age;							// Current step (one per flush cycle), derivation step, age for lambda (flush)
unsigned int phase;							 // Current phase
float lambda;										 // Current lambda - controlled by INITLAM, TARGLAM
bool PruneFlag; //NW Nov 10 - used to control aspects of pruning and showing leaves via MouseIns & MouseInsPos resp.

//NW Nov 10

//used to generate run times
time_t startsec,endsec;


float difsec;
int totSegs; //total segments produced
int gICount[9]; //production - pruning
int gBCount[9]; //new branches produced less pruning

bool doMTG; //trigger for writing mtg and xyz file during the SET_POSITIONS phase
FILE *XYZfile, *MTGfile, *MODELFIT, *BUDDATA;
char fname[24], mname[24]; //becomes the xyz and mtg filename file
char randomstring[6]; // with the help of this
char flushlab[30];
int lastNodeRead, highNode; //biggest node number read from MTG and current node node with continues there after

#define RAN_RNG(lo, hi) ((lo) + (hi - lo) * float_rand())
static float float_rand(void) { return rand() / (float) RAND_MAX; }

int gCalcNodesFlush[9], gCalcNodesBranch[9], gCalcBranchFlush[9];
float gPredictedVolume[9], gCalculatedHeightOfBranches[9], gCalculatedHeightOfFlush[9];
float gCp[9], gCanopyDepth[9], gCalculatedWidth[9];
float area;

//NW Nov 10
//creates a biased random number
int SkewRan(){
	float r=ran(1.);
	int rn=1;
	if(r>0.80){rn=3;}
	else if(r>0.60){rn=2;}
	return rn;
}

//Create a random permutation of 1,2,3 (bud.leafIndex) rather than randomly try and pick it later on
vector<int> getInitVector(const int& size)
{
	vector<int> v(size);
	for (int i=0; i<size; ++i) v[i] = i+1;
	random_shuffle(v.begin(), v.end());
	return v;
}

/* things to get rid of as they are really only debug info */
int nodeType[7];
int nPruneCaps;
/***************************/

#define STEPS 7 + 6 * FLUSHES
//#define 
derivation length: STEPS;
Axiom: SB Box(DRAWBOX) EB  SetColor(2) Orchard(NROWS, NTREES); // Seed; // SetColor(31) CurrentTexture(0) TextureVCoeff(0.15) 
//SB MoveTo(50,0,0) SetWidth(3) F(200) EB

#include "startup.hpp"

group BAIL:
production:
/*
Internode(id):
{
	//close files
	fprintf(MODELFIT,"Bailed out %i\n",gICount);
	fclose(MODELFIT);
	fclose(BUDDATA);
	produce;	
}

Bud(bd):
{
		produce;
}

Leaf(ld):
{
	produce;	
}
*/
/* READ Phase */
group READ:
production:

Orchard(r,t):
{
	Printf("Creating Orchard Layout\n");
	float xdist=INTERTREE;
	float zdist=INTERROW;
	V3f pos;
	int tn=0;
	if(r==1 && t==1){
		pos=V3f(0,0,0);
		nproduce SB MoveTo3f(pos) TreeReader(pos,0,0,0)  EB;
	} else {
		float xpos, zpos;
		float ypos=0.0;
		zpos=0-zdist/2.0*(r-1);
		for(int z=0;z<r;z++){
			xpos=0-(xdist/2.0)*(t-1);
			for(int x=0;x<t;x++){
				pos=V3f(xpos,ypos,zpos);
				Printf("%i %.2f %2.f %.2f\n",tn,xpos,ypos,zpos);
				nproduce SB TreeReader(pos,tn,z,x)  EB;
				tn++;
				xpos+=xdist;	
			}
			zpos+=zdist;
		}
	}
	produce;
}


#include "TreeReader.l"


Parab(Location,width,height):{
	float x,y,z,v;
	float a=width/2.;
	int n=61;
	float m=2*PI/(float)n;
	float sSize = min(0.5,width/200.);
	Printf("Creating Canopy Paraboloid of width %f height %f \n",width,height);
	nproduce MoveTo3f(Location) Sphere(2);
	y=0.;
	float inc=height / 30.;
	do{
  		for(int j=1;j<n;j++){
					v=j*m;
      		x=a*sqrt(y/height)*cos(v);
      		z=a*sqrt(y/height)*sin(v);
					//Printf("%f %f %f\n",x,y,z);
					nproduce MoveTo(x+Location.x,y+Location.y,z+Location.z) Sphere(sSize); //
 		 }
  	y=y+inc;
	} while (y<=height);
	produce;

}

group ADJUSTWIDTH:
production:
// rebuild widths using the Pipe Model with smallest stems set at 4 mm
// For internodes, we have to accumulate light from all supported buds and internodes
// We also take the opportunity to accumulate width for the pipe model
Internode(id):
{
	// Initialize accumulator
	float pipeAcc = 0.0;
	bool moreBranches = true;			 // true if there might be more branches left
	
	// additional data for InNewRightContext
	InternodeData rid;
	BudData rbd;
	LeafData rld;
	float w;
	// As long as there might be branches left, we use InNewRightContext to look for them

	while(moreBranches)
	{
		// 1. Internode on branch:
		if(InNewRightContext(SB Internode(rid) EB))
		{
			// Accumulate width for pipe model
			pipeAcc += pow(rid.width,PIPEEXP);
			if(SHOWPIPE)
				Printf("(Branch) id %i rid.width %.3f (%i) pipeAcc %.3f\n",id.nodenum,rid.width,rid.nodenum,pipeAcc);
		}
		
		// 2. Bud on branch:
		else if(InNewRightContext(SB Bud(rbd) EB))
		{

		}
		// 3. Pruned branch:
		else if(InNewRightContext(SB PruneCap(w) EB))
		{
			//nothing pruned at this stage
		}
		// 4. Get supply of light from leaves:
		else if(InNewRightContext(SB Leaf(rld) EB))
		{
		}
		// 5. If none of these are satisfied, we're out of branches
		else
			moreBranches = false;
	}
	
	// Now we have to do the same for whatever we're directly supporting
	// This procedure is the same as for the branches, but demand is increased by one "main" share
	if(InNewRightContext(Internode(rid)))
	{
		pipeAcc += pow(rid.width,PIPEEXP);
		if(SHOWPIPE)
				Printf("(Inode) id %i rid.width %.3f (%i) pipeAcc %.3f\n",id.nodenum,rid.width,rid.nodenum,pipeAcc);
	}
	else if(InNewRightContext(Bud(rbd)))
	{
	}
	else if(InNewRightContext(PruneCap(w)))
	{
	} else {
		
	}

	// Compute width from the pipe model accumulator
	if(pipeAcc != 0){ // supported internodes (+ pruned pipes)
		id.width = pow(pipeAcc,float(1./PIPEEXP));
		if(SHOWPIPE)
			Printf("Total %i pipeAcc %.3f %.3f\n",id.nodenum,pipeAcc,id.width);
		if(id.node==1 && id.order==0){idwidth[id.tn]=id.width;} // moved from interpretation in this model, keeps track of width of stem base
	}
	produce Internode(id);
}


group GROW:
production:
	
// Initial production handled by TreeReader


Bud(bd):
{
	//int nodenum;
	// Buds will grow if their vigor is high enough to grow at least MINNODE internode
	// One unit of vigor equals one new internode
	if(bd.vigor > MINNODES)	
	{
		float budvigor=bd.vigor; //store so we can check on how often we exceed MAXGROW
		// We only let each bud grow by at most MAXGROW per flush
		if(bd.vigor > MAXGROW) {bd.vigor = MAXGROW;} //NW Feb 11
		if(bd.order >= MAXORDER)
			bd.vigor=0.0; // need a way to redistribute this
		int numSegments = int(bd.vigor);
		gICount[bd.tn]+=numSegments;
		if(bd.tn == TREEOFINTEREST){
			totSegs+=numSegments;
		}
		
		//budn[bd.node]++;
		// length is tweaked so that total shoot length = vigor * NODELENGTH	-is this really correct
		//no it's not really suitable as length increases as the vigor increases towards the next integer
		// the effect is dminished as vigor increases, but at a vigor of 1.9 the nodelength is 9.5 cm
		//float length = (bd.vigor / float(numSegments)) * NODELENGTH;
		// it would be better to have a random or some other relationship here
		float length=NODELENGTH; // all nodes will have this length in this flush

		//Printf("\n************\n\n\n Bud\n\n****************\n");
		if (bd.lateral) { //JH setup for new branch
			bd.order++;
			gBCount[bd.tn]++;
			if(bd.tn == TREEOFINTEREST){
				
				lBudGrew++;
			}
		} else {
			if(bd.tn == TREEOFINTEREST){
				aBudGrew++;
			}
		}
		// Produce new internode;
		for(int i = 1 ; i <= numSegments ; i++)
		{
			// desired direction for growth; REORIENT * light direction	-	TROPISM * gravity
			V3f dir(REORIENT * env.getContinuousEnvDir(bd.pos,SAMPLERAD) + V3f(0,TROPISM,0));
			// set this direction as the "tropism" direction
			nproduce SetTropismDirection3f(dir);
			InternodeData newInternode( highNode++, bd.order, length);
			newInternode.tn=bd.tn;
			newInternode.rn=bd.rn;
			newInternode.pn=bd.pn;			
			;
			// First internode produced (i == 1) by a lateral bud must be "lateral"
			newInternode.budvigor=0;
			newInternode.numSegs=0;
			newInternode.length=length;
			newInternode.flushno=flushno;
			newInternode.nodenum=highNode;
			newInternode.width=0.2;
			newInternode.c=17;
			if(i ==1) {
				newInternode.lateral = bd.lateral;
				newInternode.budvigor=budvigor;
				newInternode.numSegs=numSegments;
			}
			nproduce RollL(137.5) Internode(newInternode);

			// Produce a whorl of WHORLSIZE lateral buds
			float activity=0.;
			if (i==numSegments) {activity=1.0;} 	// JH setup apical dominance via activity
			vector<int> v = getInitVector(WHORLSIZE); //Randomise the whorl bud number
			float leafsize=LEAFSCALE;
			if(i>=numSegments-1){
				leafsize=leafsize*((i-(numSegments-3))*0.1);
			}
			for(int w = 0 ; w < WHORLSIZE ; w++){
				float p=LEAFANGLE;
				nproduce SB RollR(WHORLANGLE) Down(p) Leaf(LeafData(newInternode.node,bd.order,w,p,leafsize,0,bd.tn,bd.rn,bd.pn)) EB;
				for(int bw=1;bw<=BUDSINAXIL;bw++){
					nproduce SB Down(BRANCHANGLE+((bw-1)*10.)) Bud(BudData(highNode,bd.order,v[w],bw,true,activity,bd.tn,bd.rn,bd.pn))EB ;
				}
				nproduce RollL(WHORLANGLE);
			}
		}
		// Add the Apical bud
		bd.node=highNode;
		bd.lateral=false;
		bd.axilIndex=1;
		bd.leafIndex=0;
		if(bd.order>0){bd.activity=1.0;}
		produce Bud(bd); // bd.vigor will be updated after the limit MAXGROW as been applied, so it's set like it was in BHDISTRIBUTE NW Feb 11
	} else {
		if(bd.lateral)
			lBudFail++;
		else
			aBudFail++;
		}
}

/* INTERPRET_POSITIONS phase 
* Add GetPos after each module
* Note that the positions are filled in based on the global interpretation rules (later in the file).
 * If those rules are changed, something similar must be put here (as phase-specific interpretations).
 */
group INTERPRET_POSITIONS:
production:
Internode(id):
{
	produce Internode(id) GetPos(0,0,0);
}

Bud(bd):
{
	produce Bud(bd) GetPos(0,0,0);
}

Leaf(ld):
{
	produce Leaf(ld) GetPos(0,0,0) GetHead(0,0,0);
}


/* SET_POSITIONS phase */
/* Handle position-based updates (using the shadow map) */
group SET_POSITIONS:
production:
// 1. Pruning: we have to remove pruned internodes from the shadow map
PruneCap(w) << Internode(id) GetPos(px,py,pz):
{
	// We only have to remove the internode from the shadow map if it has already been added;
	// this is only if the newInternode flag is false
	if (id.manPrune){Printf("Found %i.%i\n",id.node,id.order);}
	if(!id.newInternode && !id.isLeaf){ //we only include internodes where there isn't a leaf as leaves are put in separately,
		//env.shadow3D(V3f(px,py,pz),false);
		if(DEBUG){
			Printf("Pruned Node %i @ order %i with width %.1f\n",id.node, id.order,id.width);
		}
	}
	// Either way, we remove the internode from the tree
	gICount[id.tn]--;
	if(id.lateral)
		gBCount[id.tn]--;
	if(id.tn == TREEOFINTEREST){
		nPruned++;
		tPruned++;
	}
	//
	if(SHOWPRUNES){
		nproduce SB MoveTo(px,py,pz) SetColor(3) Sphere(1) EB;
	}
	produce;

}
// Remove buds and prune caps behind a PruneCap
PruneCap(w) << Bud(bd) GetPos(px,py,pz): {produce;}
PruneCap(w) << PruneCap(w2): { produce; }
//remove leaves
PruneCap(w) << Leaf(ld) GetPos(px,py,pz) GetHead(hx,hy,hz):
{
	if( DEBUG ){Printf("Leaf at %i %.1f %.1f %.1f\n",ld.node,px,py,pz);}
	ld.pos=V3f(px,py,pz);
	V3f head=V3f(hx,hy,hz);
	V3f midPoint=ld.pos+head*(0.5*ld.leafsize);
	if(!ld.newLeaf){// && !ld.dead){ //same reasoning as internodes, only remove from shadow map if it's been put in
		//get the exposure at this point
		env.shadow3D(midPoint,false);
		if(SHOWPRUNES){
			nproduce SB MoveTo3f(midPoint) SetColor(2) Sphere(1) EB;
			nproduce SB SetWidth(0.5) SetColor(3) Line3f(ld.pos,midPoint)  EB;
		}
	}
	produce;
}

// 2. Add new internodes (non-pruned) to the shadow map, allows for branch shading
Internode(id) GetPos(px,py,pz):
{

	if(isThisNAN(px) && ISNAN ){
		Printf("\nInternode GetPos is nodenum %i nan\n",id.nodenum);
		id.wasNAN=true;
	}  
	//check we are inside the box
	if(py>MODELSIZE || px>gModelDim || px < -gModelDim || pz > gModelDim || pz < -gModelDim){
		//Printf("\n***********************\n	You are now outside the light model!\n*********************\n");
		outsideBox=true;
	}
	// We only have to add _new_ internodes to the shadow map
	if(id.newInternode && !id.wasNAN)
	{
		id.newInternode = false;
		if(!id.isLeaf){ //only add the bare branch internodes here, leaves done separately
			env.shadow3D(V3f(px,py,pz),true);
		}
		
	}
	
	if(doMTG && !id.wasNAN){
		fprintf(XYZfile,"%.2f, %.2f, %.2f, %i\n",px,pz,py,id.order); 
		int ntype=5;
		if(id.isLeaf)
			ntype=6;
		if(id.tn == TREEOFINTEREST)
			writeMTG(MTGfile,id,MTGplantStart,MTGstack,px,py,pz,ntype,id.order,id.nodenum);
	}
	float lite=env.getContinuousExposure(V3f(px,py,pz));
	if(isThisNAN(lite))
		lite=0.0;
	id.expose=min(1.0f,max(0.f,lite)); //Nov 10 Exposure at this node
	if(isThisNAN(px))
		produce PruneCap(id.width) Internode(id);
	else {
		if(manPruning && py > PRUNEHEIGHT)
			produce PruneCap(id.width) Internode(id);
		else
			produce Internode(id);
	}
}

// 3. Record bud positions
Bud(bd) GetPos(px,py,pz):
{
	// We have to record the bud's position so we can read the accumulated light and light direction later on
	if(isThisNAN(px) && ISNAN ){
		Printf("Bud GetPos is nodenum %i nan\n",bd.node);
		nproduce SB SetColor(1) Sphere(1) EB;
	} 
	if(!isThisNAN(px)){
		bd.pos = V3f(px,py,pz);

		maxHt[bd.tn]=max(maxHt[bd.tn],py);
		if(bd.order==1){
			firstBranch[bd.tn]=min(firstBranch[bd.tn],py);
		}	
		maxX[bd.tn]=max(maxX[bd.tn],px);
		minX[bd.tn]=min(minX[bd.tn],px);
		maxZ[bd.tn]=max(maxZ[bd.tn],pz);
		minZ[bd.tn]=min(minZ[bd.tn],pz);
		maxWidthX[bd.tn]=maxX[bd.tn]-minX[bd.tn];
		maxWidthZ[bd.tn]=maxZ[bd.tn]-minZ[bd.tn];
		produce Bud(bd);
	} else
		produce;
}

// 4. Record leaf positions; add leaves to shadow map
Leaf(ld) GetPos(px,py,pz) GetHead(hx,hy,hz):
{
	if(DEBUG && ld.newLeaf){
		Printf("Leaf %i.%i at 4 %.1f %.1f %.1f H: %.1f %.1f %.1f\n",ld.node,ld.leafIndex,px,py,pz,hz,hy,hz);
		nproduce SB SetColor(87) Sphere(0.5) EB;
		}
	ld.pos = V3f(px,py,pz);
	V3f head=V3f(hx,hy,hz);
	V3f midPoint=ld.pos+head*(0.5*ld.leafsize);
	if(ld.newLeaf) {
		//nproduce SB MoveTo3f(midPoint) SetColor(80) Sphere(1) EB;
		env.shadow3D(midPoint,true);
		ld.newLeaf = false;
	}
	if(!ld.dead){
		float lite=env.getContinuousExposure(V3f(px,py,pz));
		if(isThisNAN(lite)){
			ld.expose=0.;
			ld.c=32;
		} else {
			ld.expose=min(1.0f,max(0.f,lite));
			ld.c=min(55,max(32,(int)ld.expose*7+48));
			if(flushno==FLUSHES+TREEFLUSH && lite >1.0){
				Printf("%.1f  %i\n",lite,ld.c);
				nproduce SB SetColor(1) Sphere(2) EB;
			}
		}
		if(ld.expose < LEAFEXPOSURE) { //change position to the ground, and extract a point from the shadow map
			//env.shadow3D(midPoint,false);
			//nproduce SB MoveTo3f(midPoint) SetColor(4) Sphere(1) EB;
			if (DEBUG2){
				Printf("Killed leaf with expose of %f\n",ld.expose);
			}
			ld.expose=0.;
			ld.c=104;
			ld.pos=V3f(px,0,pz);
			ld.dead=true;
			ld.fdead=flushno;
			if(SHOWDEADLEAVES){ //set dead leaves parallel to ground
				nproduce SetHead(RAN_RNG(-1.,1.),0,RAN_RNG(-1.,1.),0,1,0);
			}
		}
	}
	produce Leaf(ld);
}

/* BHACCUMULATE phase Runs Backwards*/
/* Compute light at the buds and accumulate light to the bottom of the tree */
group BHACCUMULATE:
production:

// For buds, we compute the light exposure to provide demand, but doesn't contribute to supply which is done by the Leaf
Bud(bd):
{
	// We have to keep the position bd.pos from an earlier phase for this query:
	float lite;
	lite=env.getContinuousExposure(bd.pos);
	if(isThisNAN(lite))
		lite=0.;
	bd.light = lite;
			
	if(DEBUG2)
		Printf("Bud light %f\n",bd.light);

	if (ran(1.0)< bd.light * DORMANCYFACTOR && bd.order>0) {bd.activity=1.0;} // JH changing lower bud activity
	
	/*change activity due to bud height
	This suposedly simulates the limit to tree height for this species using the hydraulic hypothesis
	
	float K=1.0; //upper limit
	float A=0.2; //lower limit
	float B=0.02; //steepness around inflection
	float Q=0.2; //the rate at which is drops from K to A
	float v=1.0;
	float M=600.0;
	bd.activity=A+(K-A)/pow((1+Q*exp(B*((float)flushno-M))),1.0/v);
	*/
	//if (ran(1.0)< bd.light * DORMANCYFACTOR && bd.order==0 && KEEPLEADER && bd.node > INITIALINTERNODES+1) {bd.activity=1.0;} // JH changing lower bud activity
	produce Bud(bd);
}

// For Leaves, we compute the light exposure to provide supply, this decouples the supply from the leaves from the demand from the buds
Leaf(ld):
{
	float lite=env.getContinuousExposure(ld.pos);
	if(ld.dead || isThisNAN(lite)){
		ld.light=0.;
	} else
	{
		/* what we might do is reduce the efficiency of upper leaves to provide vigour */
		float K=1.0; //upper limit
		float A=0.2; //lower limit
		float B=0.02; //steepness around inflection
		float Q=0.2; //the rate at which is drops from K to A
		//float v=1.0;
		float M=600.0;
		ld.light = lite * (A+(K-A)/(1+Q*exp(B*((float)flushno-M)))); //(A+(K-A)/pow((1+Q*exp(B*((float)flushno-M))),1.0/v));
		
		if(DEBUG2 && ld.light<0.1)
			Printf("Leaf light %f\n",ld.light);
		if(isThisNAN(ld.light) && ISNAN)
			nproduce SB SetColor(87)  Sphere(2) EB;
	}
	produce Leaf(ld);
}

// For internodes, we have to accumulate light from all supported buds and internodes
// We also take the opportunity to accumulate width for the pipe model
Internode(id):
{
	// Initialize accumulators
	id.count = 1;
	id.light = 0.;
	id.demand = 0.;
	float pipeAcc = 0.0;
	bool moreBranches = true;			 // true if there might be more branches left
	
	// additional data for InNewRightContext
	InternodeData rid;
	BudData rbd;
	LeafData rld;
	float w;
	// As long as there might be branches left, we use InNewRightContext to look for them
	while(moreBranches)
	{
		// 1. Internode on branch:
		if(InNewRightContext(SB Internode(rid) EB))
		{
			//Printf(" 1. Internode on branch: %i\n",id.nodenum); //OK we get here
			// Count and light are simply added
			id.count += rid.count;
			id.light += rid.light;
			//OK this is good too, added MoveTo3f to ignore list
			// Demand is incremented by one lateral share
			id.demand += rid.count * (1.-lambda) * pow(rid.light / rid.count,NONLINEAR);

			// Accumulate width for pipe model
			pipeAcc += pow(rid.width,PIPEEXP);
			if(SHOWPIPE)
				Printf("(Branch) rid.width %.3f (%i) pipeAcc %.3f\n",rid.width,rid.nodenum,pipeAcc);
		}
		
		// 2. Bud on branch:
		else if(InNewRightContext(SB Bud(rbd) EB))
		{
			// Count of a bud is just one
			id.count++;
			//Printf(" 2. Bud on branch: %i\n",id.nodenum); //OK we get here
			// Add one lateral share to demand depending on activity
			float act=1.0;
			if(USEACT ){act=rbd.activity;}
			id.demand += (1.-lambda) * act * pow(rbd.light,NONLINEAR);
		}
		// 3. Pruned branch:
		else if(InNewRightContext(SB PruneCap(w) EB))
		{
			// No light or vigor; just increment the pipe accumulator
			//Printf("3. PruneCap\n"); //All good with this too
			pipeAcc += pow(w,PIPEEXP);
		}
		// 4. Get supply of light from leaves:
		else if(InNewRightContext(SB Leaf(rld) EB))
		{
			//Increment light
			id.light += rld.light;
		}
		// 5. If none of these are satisfied, we're out of branches
		else
			//Printf("at nodenum %i out of branches\n",id.nodenum);
			moreBranches = false;
	}
	
	// Now we have to do the same for whatever we're directly supporting
	// This procedure is the same as for the branches, but demand is increased by one "main" share
	if(InNewRightContext(Internode(rid)))
	{
		id.count += rid.count;
		id.light += rid.light;
		//Printf("Inode light %f\n",id.light);
		// main shoot => relative strength lambda
		id.demand += rid.count * lambda * pow(rid.light / rid.count,NONLINEAR);
		pipeAcc += pow(rid.width,PIPEEXP);
		if(SHOWPIPE)
			Printf("(Inode) rid.width %.3f (%i) pipeAcc %.3f\n",rid.width,rid.nodenum,pipeAcc);
	}
	else if(InNewRightContext(Bud(rbd)))
	{
		id.count += 1;
		id.light += rbd.light;
		//Printf("Bud light %f\n",id.light);
		float act=1.0;
		if(USEACT){act=rbd.activity;}
		id.demand += lambda * act * pow(rbd.light,NONLINEAR);
	}
	else if(InNewRightContext(PruneCap(w)))
	{
		pipeAcc += pow(w,PIPEEXP);
	}

	// Compute width from the pipe model accumulator
	if(pipeAcc != 0){ // supported internodes (+ pruned pipes)
		id.width = pow(pipeAcc,float(1./PIPEEXP));
		if(SHOWPIPE)
			Printf("Total %i pipeAcc %.3f %.3f\n",id.nodenum,pipeAcc,id.width);
		if(id.node==1 && id.order==0)
			idwidth[id.tn]=id.width;
	}
	// Update internode values
	//if(id.order < 2)
	//	Printf("Branch Order %i %i %f count %i\n",id.order,id.nodenum,id.light,id.count);
	produce Internode(id);
}


/* BHDISTRIBUTE phase */
/* Compute vigor from light and distribute to the tree using the Borchert-Honda allocation model */
group BHDISTRIBUTE:
// 1. Total vigor is computed from total light at the basal internode
Roots(pos,tn,rn,pn) < Internode(id):
{
	float seasonalLightFactor;
	if(flushno % 2 == 0)
		seasonalLightFactor=LIGHTFACTOR;
	else
		seasonalLightFactor= LIGHTFACTOR * WINTER;
	float K=1.0; //upper limit
	float A=0.6; //lower limit
	float B=0.9; //steppness around inflection
	float Q=0.2; //the rate at which is drops from K to A
	float v=1.0; //
	float M=13.0; //inflection pt when Q=v
	float LFF = 1.0;// A+(K-A)/pow((1+Q*exp(B*((float)flushno-M))),1.0/v);
	//seasonalLightFactor=LIGHTFACTOR*LFF;
	if(id.light == 0.0)
		id.vigor = INITIALFLUX; //INITIALFLUX is important in the first instance if there is no light
	else
		id.vigor=seasonalLightFactor * id.light;
	
	Printf("Tree (%i): Total light at base = %g ==> total vigor = %g\n",tn,id.light,id.vigor);
	if(flushno >= 7)
		gLightAtBase[id.tn]=id.light;
	Printf("%d supported entities\n",id.count);
	produce Internode(id);
}

// 2. All other internodes
Internode(lid) << Internode(id):
{
	// We can claim a share of our parent's vigor proportional to how much of its total demand parameter is ours
	float myDemand;
	// Our demand = lam * count * pow(light/count , NONLINEAR),
			// where lam = lambda if we're apical, lam = (1 - lambda) if we're lateral

	myDemand=id.count * pow(id.light / id.count,NONLINEAR);

	if(id.lateral)
		myDemand *= 1. - lambda;
	else
		myDemand *= lambda;

	// Update our vigor
	if(lid.demand>0.){
		id.vigor = lid.vigor * (myDemand / lid.demand);
	} else
	{
		id.vigor=lid.vigor;
	}
	if(id.node==1 && SHOWB)
		Printf("%i << %i id.count %i lid.vigor %.2f mydemand %.2f lid.demand %.2f\n",lid.nodenum,id.nodenum,id.count,lid.vigor,myDemand,lid.demand);
	produce Internode(id);
}

// 3. Buds
Internode(lid) << Bud(bd):
{
	//buds are released based on the bud number held in bd.leafIndex 
	//	(at present from 1 to 3, but the numbers are assigned randomly)
	int rn=SkewRan();
	if(lid.order==0){rn=3;} //so that each of the first order buds always get their vigor
	if(bd.lateral && bd.leafIndex > rn ){
		bd.vigor=0.;
	}
	else	// a chosen lateral or an apex
	{
		// Claim a share of the parent's vigor
		// Our demand = lam * pow(light , NONLINEAR),
		// where lam = lambda if we're apical, lam = (1 - lambda) if we're lateral
		float myDemand = pow(bd.light,NONLINEAR)*bd.activity;	//?????????should activity be here
		if(bd.lateral)
			myDemand *= 1. - lambda;
		else
			myDemand *= lambda;
		// Update our vigor
		if(lid.demand>0.){
			bd.vigor = lid.vigor * (myDemand / lid.demand);
		} else {
			bd.vigor=lid.vigor;
		}
		//if(bd.leafIndex==1){Printf("bud light %f lid.vigor %f demand %f\n",bd.light,lid.vigor,lid.demand);}
		// We only let each bud grow by at most MAXGROW per flush
		//if(bd.vigor > MAXGROW)	bd.vigor = MAXGROW;	//this seems to be in the wrong place see NW Feb 11 - moved to Bud in GROW
	}
	produce Bud(bd);
}

//4.0 Leaves - upadte branch width so leaves don't start with branches - which looks silly
Internode(lid) << Leaf(ld):
{
	ld.bWidth=lid.width;
	ld.age=ld.age+0.5;
	if(ld.leafsize < LEAFSCALE)
		ld.leafsize=min(LEAFSCALE,ld.leafsize*2.0*ld.age); //first time thru don't alter size, after that they should become LEAFSCALE size
	produce Leaf(ld);
}

/* PRUNE phase */
/* Prune inefficient branches from outside in */
// this runs in Backwards direction
group PRUNE:
production:
// trunk immune to pruning
Roots(pos,tn,rn,pn) < Internode(id) : { produce Internode(id); }


// Other internodes:
Internode(id):
{
	// Since some supported branches may have been pruned at some time in this step,
	// we have to recompute id.count as we go; this is done in pretty much the same
	// way as we compute it initially, up in BHACCUMULATE.

	//we already have this info so no need to do it again
	 
	// We prune if there's not enough vigor allocated for the size of the branch
	// This is vigor / count; if it's too low (below DROPTHRESH), we prune.
	if(id.vigor < 0 ){
		Printf("Warning id.vigor < 0 \n");
	}
	if((id.vigor / float(id.count)) < DROPTHRESH && id.order > 1)
	{
		//Printf("Prune test %f<%f\n",id.vigor / float(id.count),DROPTHRESH);
		nPruneCaps++;
		produce PruneCap(id.width) Internode(id);
	}
	else
		produce Internode(id);
}

/*
 * If we're OK with pruning from the inside out, all of this can be done with a single
 * Internode production in the GROW phase:
 *
 * Internode(id) :
 * {
 *	 if((id.vigor / float(id.count)) <= DROPTHRESH)
 *		 produce PruneCap(id.width) Internode(id);
 * }
 *
 */



/* Global rules */
group 0:
//NW Nov 10
production:

MouseIns() < Internode(id):
{
	Printf("****** Marking ID %i.%i\n",id.nodenum,id.order);
	id.manPrune=true;
	//sprintf(flushlab,"             %i",id.nodenum);
	produce PruneCap(id.width) Internode(id); // Label(flushlab);
}

MouseInsPos(MouseStatus):
{
	Printf("*******************\nPruning at %icm\n*************\n",PRUNEHEIGHT);
	manPruning=true;
	produce;
}



interpretation:
Box(draw):
{
	if(draw){		
		nproduce SB SetColor(0) SetWidth(3) MoveTo(-gModelDim,0,-gModelDim);
		for(int i=0;i<4;i++){
			nproduce LineTo3f(V3f(X[i],0,Z[i]));
		}
		nproduce MoveTo(-gModelDim,gModelDim*2.0,-gModelDim);
		for(int i=0;i<4;i++){
			nproduce LineTo3f(V3f(X[i],gModelDim*2.0,Z[i]));
		}
		for(int i=0;i<4;i++){
			nproduce MoveTo(X[i],0,Z[i]) LineTo3f(V3f(X[i],gModelDim*2.0,Z[i]));
		}
		produce EB;
	}
}

// In Roots, we just set up initial values: position, orientation, elasticity
Roots(pos,tn,rn,pn):
{
	
	
	if(NROWS==1 && NTREES==1){
		sprintf(flushlab,"Flush %d Age %i (%.2f) %i",flushno,age,lambda,step);
		nproduce SB SetColor(1) MoveTo(30,5,0) Label(flushlab) EB ;
	}
	else{
		//sprintf(gALabel,"Flush %d Age %i (%.2f, %.1f) %i",gFlushNo,gAge,gLambda,gICount/float(gBCount),gStep);
		//nproduce SB SetColor(1) MoveTo(MODELDimension*.7,5,MODELDimension*0.7) Label(gALabel) EB ;
		sprintf(flushlab,"TN: %i",tn);
		nproduce SB MoveTo3f(pos) Label(flushlab) EB;
	}
	produce MoveTo3f(pos) Elasticity(TROPISMELASTICITY); //
}

// Each internode is just drawn as a line of the required length and width
Internode(id):
{
/*	if(SHOWBRANCHES){
		int clr = 17;
		float wd=id.width;
//		if(id.nodenum <= lastNodeRead)
//			clr=104;
//		else
//			clr=64;
		if(id.flushno == flushno){
			clr=49;
			wd=1.0;
		}
		produce SetColor(clr) SetWidth(wd) F(id.length) ;
	} else {
			nproduce f(id.length) ;
	}
	if(SHOWBALLS && id.node == 1){
		sprintf(flushlab,"      %i\n",id.nodenum);
		nproduce Label(flushlab);
	}
	produce;*/
	
	if(id.rn == ROWOFINTEREST || ROWOFINTEREST == -1)
		produce SetColor(id.c) SetWidth(id.width) F(id.length) ;
	else
		produce f(id.length);
}

Leaf(ld):
{
//	int lc=ld.c;
//	if(SHOWONLYDEADLEAVES){ 
//
//		if(ld.expose<LEAFEXPOSURE){ //show dead leaves in situ
//				nproduce SetWidth(0.2) SetColor(109+flushno) F(ld.leafsize*0.1) Surface(LEAF,ld.leafsize*0.5); //had to bring RollR inside as it did weird things to tree when it preceeded it. Down(ld.pitch)
//		}
//	} else
//	{
//		if ((SHOWLEAVES || (SHOWLEAVESLAST && flushno == FLUSHES )) ) {
//			if(!ld.dead and ld.expose > 0.5){ //shows the live leaves
//				//Printf("Leaf expose	%.1f x,y,z %.1f %.1f %.1f\n",ld.expose,ld.pos.x,ld.pos.y,ld.pos.z);
//				nproduce SetWidth(0.2) SetColor(lc) F(ld.leafsize*0.1) Surface(LEAF,ld.leafsize); //had to bring RollR inside as it did weird things to tree when it preceeded it.  Down(ld.pitch)
//			} else
//			{
//				if(SHOWDEADLEAVES){ //shows dead leaves on the ground
//					nproduce SB SetColor(104+(flushno-ld.fdead)) MoveTo(ld.pos.x,0,ld.pos.z) Surface(LEAF,ld.leafsize) EB; //
//				}
//			}
//		}
//	}
	
	if(SHOWLEAVES)
		produce SetWidth(0.2) SetColor(ld.c) F(ld.leafsize*0.1) Surface(LEAF,ld.leafsize);
}

// Buds
/*
Bud(bd):
{	
	if(SHOWLATERALBUDS  && bd.lateral && bd.order==0){ // && bd.activity > 0
		nproduce SB SetColor(132) Sphere(2) EB;
	}
	if(SHOWOTHERBUDS  && !bd.lateral && bd.order==0){
		nproduce SB SetColor(84) Sphere(2) EB;
	}
	produce;
}


PruneCap(w):
{
	
	if(SHOWPRUNECAP){
		produce SB SetColor(1) Sphere(2) EB;
	}
}

MouseIns():
{
	produce;// SetColor(2) Sphere(1);
}

*/