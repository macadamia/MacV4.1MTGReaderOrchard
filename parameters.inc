//Run Parameters
#define Condor false
#define NODESTOREAD 9999999
#define DEBUG false
#define DEBUG2 false
#define SHOWB false
#define PARAB false
#define ISNAN false
#define DRAWBOX false
// final flush number (2 flushes per year),
#define FLUSHES 13
//starting number of flushes and age
#define TREEFLUSH 5
#define TREEAGE 2
//set XYZFLUSH to FLUSHES+TREEFLUSH number or -1 for no MTG/XYZ creation
#define XYZFLUSH FLUSHES+TREEFLUSH

#define WINTER 0.4f

//Orchard is NROWS x NTREES
#define NROWS 3
#define NTREES 3
//set TREEOFINTREST to 0 for 1 tree and 4 for 9 trees
#define TREEOFINTEREST 4
//set ROWOFINTEREST to -1 for all, 99 for none, or 1 for the middle row
#define ROWOFINTEREST -1
//spacing in cm
#define INTERROW 850
#define INTERTREE 450


//TreeReader.l
#define SHOWBALLS false
#define SHOWPIPE false

//where to get the mtg data from
#ifdef __APPLE__
#define MTGDIR "/Users/neil/Dropbox/MTGs/"
#define PYTHON "/BLAH/"
#endif
#ifdef __linux__
#define MTGDIR "/home/neil/Dropbox/MTGs/"
#define PYTHON "/usr/bin/python"
#endif
#ifdef _WIN32
#define MTGDIR "C:/Users/whiten/Dropbox/MTGs/"
#define PYTHON "C:/python27/python.exe"
#endif

//#define MTGFILE "842/Plant05_Pruned.mtg"
//#define MTGFILE "842/Plant05.mtg"
//#define MTGFILE "842/Plant05_240510.mtg"
//#define MTGFILE "842/Plant06.mtg"
//#define MTGFILE "842/Plant07.mtg"
//#define MTGFILE "842/Plant07_edited.mtg"
//#define MTGFILE "842/Plant07_20100427.edited.mtg"
//#define MTGFILE "842/Plant07_20100907finalEdited.mtg"
//#define MTGFILE "842/Plant07_Test.mtg"

#define MTGFILE "816/Plant02.mtg"
//#define MTGFILE "816/Plant01_20100323.mtg"
//#define MTGFILE "741/Plant15.mtg"
//#define MTGFILE "A268/Plant21.mtg"
//#define MTGFILE "Daddow/Plant23.mtg"

//#define MTGFILE "842/Plant20.mtg"
//#define MTGFILE "842/Plant19.mtg"


//use randomly generated file names for MTG and XYZ file
#define USERANDFNAMES false
//random number seed set as time(0) or an INT
#define RSEED time(0)
//#define RSEED 1369568156

//LightModel
//useful modelsizes and densities
// (800 76) (1000 95 ) (1400 133) (1800 171) (2200 209) (2600 247)
#define MODELSIZE 2600.0f
#define DENSITY 247
#define SPREAD 3.0
#define DEPTH 2
#define STRENGTH 0.7
#define FADE 4.0
#define SAMPLERAD 2
//add some randomness
#define Ran 0.001
#define Vert 0.0

//structral elements
#define WHORLSIZE 3	// Number of buds produced at each node
#define BUDSINAXIL 1 	// number of lateral buds at each leaf // NW Nov 10
#define WHORLANGLE (360. / float(WHORLSIZE))	// Angle between individual leaves at a node.
// Successive internodes will be rotated by 137.5 + (WHORLSIZE * WHORLANGLE) with respect to each other.
#define PIPEEXP 3.0f
//branches greater than order MAXORDER no longer create laterals
#define MAXORDER 8
#define MINNODES 2
#define NODELENGTH getNorm(4.6, 0.5, 1.0, 12.0)
#define MAXGROW getNorm(14., 1.0, 1.0, 12.0)
#define BRANCHANGLE RAN_RNG(45.0,55.0)
#define LEAFANGLE getNorm(64.,20.,3.,150.)
#define LEAFSCALE 15.0
#define PRUNEHEIGHT 290.0
//corresponds to order in view.v (zero start)
#define LEAF 3

//Behaviour
#define USEACT true
#define DORMANCYFACTOR 1.0
#define TROPISMELASTICITY 0.1

//Response to light
#define INITIALFLUX 60.0
#define LIGHTFACTOR 18.0f
#define LEAFEXPOSURE 0.01f
#define DROPTHRESH 0.02
#define NONLINEAR 1.0f
#define TROPISM 0.3
#define REORIENT 0.8
#define INITLAM 0.5
#define TARGLAM 0.5
#define TRANSITION 6
#define DELAY 2

//interpretation
//show where self pruning occurs
#define SHOWPRUNECAP false
//always draw leaves
#define SHOWLEAVES false
//draw leaves on last step 
//#define SHOWLEAVESLAST false
//show dead leaves on the ground
#define SHOWDEADLEAVES false
//show dead leaves where they died on the plant
#define SHOWONLYDEADLEAVES false
#define SHOWLATERALBUDS false
#define SHOWOTHERBUDS false
#define SHOWPRUNES false
#define SHOWBRANCHES true
#define SHOWLABEL true
