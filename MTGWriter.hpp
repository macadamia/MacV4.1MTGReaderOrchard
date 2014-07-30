#include <iostream>
//MTG structure
#define MAXORDERS 20
#define mtgSTRUCTURE 0
#define mtgNODE 1
#define mtgDATA 2
#define mtgCREATE 1
int MTGcurOrder;
int MTGstack[MAXORDERS][mtgDATA];
bool MTGplantStart, MTGlatStart; 

void writeLine(FILE *MTGfile, float x,float y, float z, float wd,int fno,float vig, int nsegs, float nlen, int ntype, int level, int theNodeNum){
	//theNodeNum++;
	fprintf(MTGfile, "%.2f	%.2f	%.2f	%.2f	%i	%.2f	%i	%.2f	%i	%i	%i\n",x,y,z,wd,fno,vig,nsegs,nlen,ntype,theNodeNum,level);
}

void createMTG(FILE *MTGfile, int (&MTGstack)[MAXORDERS][mtgDATA], int &MTGcurOrder, bool &MTGplantStart, bool &MTGlatStart)
{
	time_t rawtime;
  struct tm * timeinfo;

  time ( &rawtime );
  timeinfo = localtime ( &rawtime );
  fprintf ( MTGfile,"#Created: %s", asctime (timeinfo) );
  fprintf(MTGfile,"# input file was %s\n",MTGFILE);
	// for reading of parameters.inc and insertion into MTGfile
	//char p1[512];
	//char p2[512];
	//char p3[512];
	//ifstream fp;
	string line;

	// creation of MTG preamble
	//set initial conditions, plant is the highest scale and order 0, there is no lateral branch
	MTGcurOrder=0;
	MTGstack[MTGcurOrder][mtgSTRUCTURE]=1;		
	MTGstack[MTGcurOrder][mtgNODE]=1;
	MTGplantStart=true;
	MTGlatStart=false;

/*
	//insert mtgOUTPTAGE in MTGfile
	//fprintf(MTGfile, "#Flushes: %i\n",mtgOUTPUTAGE);
	//insert parameters.inc at top of file
	ifstream Pfile ("parameters.inc");
	while (getline(Pfile,line)){
		fprintf(MTGfile,"%s\n",line.c_str());
	}
	Pfile.close();
*/
	// preamble
	fprintf(MTGfile, "CODE:	FORM-A\n");
	fprintf(MTGfile, "CLASSES:\n");
	fprintf(MTGfile, "SYMBOL	SCALE	DECOMPOSITION	INDEXATION	DEFINITION\n");
	fprintf(MTGfile, "$	0	FREE	FREE	IMPLICIT\n");
	fprintf(MTGfile, "P	1	CONNECTED	FREE	EXPLICIT\n");
	fprintf(MTGfile, "S	2	CONNECTED	FREE	EXPLICIT\n");
	fprintf(MTGfile, "N	3	CONNECTED	FREE	EXPLICIT\n");
	fprintf(MTGfile, "\n");

	fprintf(MTGfile, "DESCRIPTION:\n");
	fprintf(MTGfile, "LEFT	RIGHT	RELTYPE	MAX\n");
	fprintf(MTGfile, "S	S	+	?\n");
	fprintf(MTGfile, "S	S	<	?\n");
	fprintf(MTGfile, "N	N	<	?\n");
	fprintf(MTGfile, "N	N	+	?\n");
	fprintf(MTGfile, "\n");
	fprintf(MTGfile, "FEATURES:\n");
	fprintf(MTGfile, "NAME	TYPE\n");
	fprintf(MTGfile, "\n");
	fprintf(MTGfile, "XX\tREAL\n");
	fprintf(MTGfile, "YY\tREAL\n");
	fprintf(MTGfile, "ZZ\tREAL\n");
	fprintf(MTGfile,"TopDia	REAL\n");
	fprintf(MTGfile,"FlushNo\tINT\n");
	fprintf(MTGfile,"FlushLen\tREAL\n");
	fprintf(MTGfile,"NumSegs\tINT\n");
	fprintf(MTGfile,"ILength\tREAL\n");
	fprintf(MTGfile,"NType\tINT\n");
	fprintf(MTGfile,"Node\tINT\n");
	fprintf(MTGfile,"Level\tINT\n");
	fprintf(MTGfile, "\n");
	fprintf(MTGfile, "MTG:\n");
	fprintf(MTGfile, "\n");
	fprintf(MTGfile, "ENTITY-CODE");
	for (int i=0;i<=MAXORDERS; i++) { // print number of tabs for current order
  		fprintf(MTGfile, "	");
	}
	fprintf(MTGfile, "XX	YY	ZZ	TopDia	FlushNo	FlushLen	NumSegs	ILength	NType	Node	Level\n");
}


void writeMTG(FILE *MTGfile, InternodeData id, bool &MTGplantStart, int (&MTGstack)[MAXORDERS][mtgDATA], float px, float py, float pz, int ntype, int level, int nodenum)
{
	if (MTGplantStart) {
		fprintf(MTGfile, "/P1/S%d",MTGstack[MTGcurOrder][mtgSTRUCTURE]);
		for (int i=0;i<=MAXORDERS; i++) { // print number of tabs for previous order
			fprintf(MTGfile, "	");
		}
		// convert from cm in the model to mm, since the plants are done that way when they are digitised
		writeLine(MTGfile,0.,0.,0., id.width*10.,id.flushno,id.budvigor,id.numSegs,id.iNodeLen*10,5,1,nodenum);
		MTGplantStart=false;
	}
	if(MTGcurOrder > id.order){
		if(id.lateral){
			MTGstack[id.order][mtgNODE]=1;
			MTGstack[id.order][mtgSTRUCTURE]++;
		}
		else {
			MTGstack[MTGcurOrder][mtgSTRUCTURE]=1; //this was a == here
		}
	}
	if(MTGcurOrder < id.order){
		MTGstack[id.order][mtgSTRUCTURE]=1;
		MTGstack[id.order][mtgNODE]=1;
	}
	if(MTGcurOrder == id.order && id.lateral){
		MTGstack[id.order][mtgSTRUCTURE]++;
		MTGstack[id.order][mtgNODE]=1;
	}
	if(id.order-MTGcurOrder>1)
		Printf("%i %i %i\n",theNodeNum+1,id.order,MTGcurOrder);
		MTGcurOrder=id.order;
	//if (MTGlatStart) { //JH Dec2009
	if(id.lateral || (MTGstack[MTGcurOrder][mtgNODE]==1 && MTGcurOrder >0 ) ) { //NW Nov 2010, updated 6 Feb 2013, handles pruned branches
		
		for (int i=1;i<=MTGcurOrder; i++) { // print number of tabs for previous order
			fprintf(MTGfile, "	");
		}
		fprintf(MTGfile, "+S%d", MTGstack[MTGcurOrder][mtgSTRUCTURE]);
		for (int i=MTGcurOrder;i<=MAXORDERS; i++) { // print number of tabs for current order
			fprintf(MTGfile, "	");
		}
		writeLine(MTGfile, pz*10.,px*10.,py*10., id.width*10.,id.flushno, id.budvigor,id.numSegs,id.iNodeLen*10.,ntype,level,nodenum);

		for (int i=1;i<=MTGcurOrder; i++) { // print number of tabs for current order
			fprintf(MTGfile, "	");
		}
		fprintf(MTGfile, "^/N%d", MTGstack[MTGcurOrder][mtgNODE]);
		for (int i=MTGcurOrder;i<=MAXORDERS; i++) { // print number of tabs for current order
			fprintf(MTGfile, "	");
		}
		writeLine(MTGfile,pz*10.,px*10.,py*10., id.width*10.,id.flushno, id.budvigor,id.numSegs,id.iNodeLen*10.,ntype,level,nodenum);
		MTGlatStart=false;
	}
	else {
		for (int i=1;i<=MTGcurOrder; i++) { // print number of tabs for current order
			fprintf(MTGfile, "	");
		}
		/* updated 6 Feb 2013, handles pruned branches
		if (MTGstack[MTGcurOrder][mtgNODE]==1) {
			fprintf(MTGfile, "^/N%d", MTGstack[MTGcurOrder][mtgNODE]);
		}
		else {
		*/
			fprintf(MTGfile, "^<N%d", MTGstack[MTGcurOrder][mtgNODE]);
		//}
		for (int i=MTGcurOrder;i<=MAXORDERS; i++) { // print number of tabs for current order
			fprintf(MTGfile, "	");
		}
		writeLine(MTGfile,pz*10.,px*10.,py*10., id.width*10.,id.flushno, id.budvigor,id.numSegs,id.iNodeLen*10.,ntype,level,nodenum);
	}
	MTGstack[MTGcurOrder][mtgNODE]++;
}
