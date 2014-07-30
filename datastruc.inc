/* Data structure for internodes */
struct InternodeData
{
  bool lateral;          // The base internode of each branch has lateral=true
  bool isLeaf;		//allow leaf to be here NW Nov 10
  bool manPrune; // manual pruning using MouseIns NW Nov 10
  int node, order; //JH  node number on current branch and order of branch
  int nodenum; // actual nodenumber in MTG file
  float light;           // The amount of light collected by this internode and its supported branch
  float expose;		//NW Nov 10 the amount of light exposure at this node
  float vigor;           // The amount of vigor allocated to this internode and its supported branch
  float demand;          // The total "demand" parameter of this internode's immediate children
  unsigned int count;    // The number of supported entities (internodes and buds)
  bool newInternode;     // New internodes have this set to true, and are added to the shadow map
  float budvigor;			//NW Feb 11 vigor of bud that iniitiated this flush without MAXGROW limitation
  int numSegs;					// NW Feb 11 actual number of segments produced after MAXGROW applied
  float iNodeLen;		// length (cm) of internode
  int flushno;  // the flush number
  int c; //colour
  bool wasNAN;
  int tn,rn, pn; // tree number, row, plant in row

  float length, width;   // Length and width; length does not change, width changes according to pipe model

  InternodeData(bool _lateral = false)
    : node(0), order(0), length(NODELENGTH) , width(1.5) , lateral(_lateral) ,  //intial width set to 0.2 and PIPEXEP is set to 2 (thanks da Vinci) Neil April 2011
      light(0.) , expose(0.), vigor(0.) , demand(0.) , count(0) , nodenum(0),
      newInternode(true), isLeaf(true), manPrune(false), budvigor(0), numSegs(0), iNodeLen(0.), flushno(0), c(16), wasNAN(false), tn(0), rn(0), pn(0)
  {}

  InternodeData(int _nod, int _ord, float _length, bool _lateral = false , bool _leaf=true)
    : node(_nod), order(_ord), length(_length) , width(1.5) , lateral(_lateral) ,
      light(0.) , expose(0.), vigor(0.) , demand(0.) , count(0) , nodenum(0),
      newInternode(true) , isLeaf(_leaf), manPrune(false), budvigor(0),numSegs(0), iNodeLen(0.), flushno(0),c(16), wasNAN(false), tn(0), rn(0), pn(0)
  {}
};

/* Data structure for buds */
struct BudData
{
  bool lateral;          // Lateral buds have this set to true
  int node, order; //JH		node number on current branch and order of branch
  float light;           // Amount of light collected by this bud (read from shadow map)
  float vigor;           // Amount of vigor allocated to this bud
  float activity;  //JH 	states: inactive 0 or active 1; level of activity inbetween

  unsigned int axilIndex; // Index of this bud in whorl
  unsigned int leafIndex; // index of the whorl we are in

  V3f pos;               // Position of this bud; must be recorded and used in a successive phase
  int tn, rn, pn; // tree number, row number, plant in row

  BudData(int _nod=0, int _ord=0, unsigned int _leaf = 1,unsigned int _axil=0, bool _lateral = false,  float _act=1.0, int _tn=0, int _rn=0, int _pn=0)
    :  node(_nod), order(_ord), leafIndex(_leaf), axilIndex(_axil), lateral(_lateral), light(0), vigor(0), activity(_act), pos(), tn(_tn), rn(_rn), pn(_pn)
  {}
};

/* Data structure for leaves */
struct LeafData
{
  int node, order; 	//JH node number on current branch and order of branch
  unsigned int leafIndex; // Index of this leaf in whorl
  float leafsize;         //leaf scale factor (should be cm)
  float pitch;            //leaf pitch (used in Down)
  float down;             //used to correct pitch to flat when leaves are dead
  float expose;            // leaf exposure from shadow map
  V3f pos;               // Position of this leaf; must be recorded and used in a successive phase
  bool dead;             //id dropped mark as dead
  int fdead;                //leaf died at flush n
  float light;		// leaf light exposure to drive supply
  bool newLeaf;        //when leaf is first added this is true

  float bWidth;	//width of node
  float age;
  int c; //colour
  int tn, rn, pn; // tree number, row number, plant in row

  LeafData(int _nod=0, int _ord=0,  unsigned int _index = 1, float _p=0., float _ls=0., float _lt=0., int _tn=0, int _rn=0, int _pn=0)
    :  node(_nod), order(_ord), leafIndex(_index),  pitch(_p) , down(0.), expose(0.), leafsize(_ls), pos(), dead(false), fdead(0), light(_lt), newLeaf(true), bWidth(0), age(0), c(0), tn(_tn), rn(_rn), pn(_pn)
  {}
};
