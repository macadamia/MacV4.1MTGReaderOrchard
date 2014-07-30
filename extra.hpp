
#define PI 3.141593f
int theNodeNum=1; // used for creating the MTG, increments each time a line is written 

double randn_trig(double mu=0.0, double sigma=1.0) {
	static bool deviateAvailable=false;	//	flag
	static float storedDeviate;			//	deviate from previous calculation
	double dist, angle;
	
	//	If no deviate has been stored, the standard Box-Muller transformation is 
	//	performed, producing two independent normally-distributed random
	//	deviates.  One is stored for the next round, and one is returned.
	if (!deviateAvailable) {
		
		//	choose a pair of uniformly distributed deviates, one for the
		//	distance and one for the angle, and perform transformations
		dist=sqrt( -2.0 * log(double(rand()) / double(RAND_MAX)) );
		angle=2.0 * PI * (double(rand()) / double(RAND_MAX));
		
		//	calculate and store first deviate and set flag
		storedDeviate=dist*cos(angle);
		deviateAvailable=true;
		
		//	calcaulate return second deviate
		return dist * sin(angle) * sigma + mu;
	}
	
	//	If a deviate is available from a previous call to this function, it is
	//	returned, and the flag is set to false.
	else {
		deviateAvailable=false;
		return storedDeviate*sigma + mu;
	}
}

float dist3f(V3f sp,V3f ep){
	float dist;
	dist=sqrt(pow(sp.x-ep.x,2.f)+pow(sp.y-ep.y,2.f)+pow(sp.z-ep.z,2.f));
	return dist;	
}


double getNorm(double m, double s, double l, double u){
double rn=0.0;
int cnt=0;

while ( rn < l || rn > u) {
		rn = randn_trig(m, s);
		cnt++;
		if (cnt > 1000) {
			rn=m;
			break;
		}
	}
	return rn;
}

//gen a random name for mtgfile -needs cleaning up
std::string randomString(int length) {
	// the shortest way to do this is to create a string, containing
	// all possible values. Then, simply add a random value from that string
	// to our return value
	std::string allPossible; // this will contain all necessary characters
	std::string str; // the random string
	// letters, we'll add letters to the possibilities
	for (int i = 65; i <= 90; i++) {
			allPossible += static_cast<char>(i);
			allPossible += static_cast<char>(i+32); // add a lower case letter, too!
	}
	// get the number of characters to use (used for rand())
	int numberOfPossibilities = allPossible.length();
	for (int i = 0; i < length; i++) {
			str += allPossible[rand() % numberOfPossibilities];
	}

		return str;
}
//prints tabs based on Order
int tabs(int ntabs){
	for(int i=0;i<ntabs;i++){
		Printf("   ");
	}
	return 0;
}

