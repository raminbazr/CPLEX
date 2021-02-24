//Sets

//Periods
int T=3;
range periods=1..T;

//Nodes
int N=2;
range nodes=0..N;
range hospitals=1..N;

//Vehicles
int K=2;
range vehicles=1..K;


//Parameters

float M[periods]=[3000,2500,2800]; //Maximal quantity of the blood product produced at the blood center in time period t (product unit)

int z=2; //The shelf life of the blood product (period)

float w=70; //Unit penalty cost for blood wastage ($/product unit)

float l[nodes]=[5000,1500,1700]; //Storage capacity of transportation node i (product unit)

float u[hospitals][periods]=[[500,1200,900],[1000,850,650]]; //Demand of hospital i in time period t (product unit)

float h[nodes]=[50,40,35]; //Unit inventory holding cost at hospital i ($/product unit)

float e[hospitals][periods]=[[25,30,25],[30,40,20]]; //Unit penalty cost for blood shortage at hospital i in time period t ($/product unit)

float cv[vehicles]=[1000,1500]; //Capacity of vehicle k (product unit)

int V=1000;
float Ac[i in nodes][j in nodes]=(i<j)?rand(100)+rand(50):0;
float dis[i in nodes][j in nodes]=(i<j)?Ac[i][j]:(i>j)?Ac[j][i]:V; //Distance between nodes i and j (km)

float fc[vehicles]=[15000,18000]; //Fixed transportation cost for vehicle k ($)

float vc[vehicles]=[0.6,0.9]; //Variable transportation cost for vehicle k ($/product unit * km)

float pc[hospitals]=[15,20]; //Pickup cost (transshipment) in hospital i ($/product unit)

range ss = 0..ftoi((2^N)-1);
{int} sub [s in ss] = {i | i in 1..N: (s div ftoi(2^(i-1))) mod 2 == 1}; //Subsets of nodes


//Decision Variable   
                     
dvar float+ p[periods]; //Quantity of the blood product produced at the blood center in time period t

dvar boolean y[nodes][vehicles][periods]; //A binary variable, if hospital i is served by vehicle k in time period t, y = 1 ; otherwise, y = 0

dvar float+ dq[hospitals][vehicles][periods]; //Quantity of the blood product delivered to hospital i by vehicle k in time period t

dvar float+ pq[hospitals][vehicles][periods]; //Quantity of the blood product picked up from hospital i by vehicle k in time period t

dvar boolean x[nodes][nodes][vehicles][periods]; //A binary variable, if the delivery vehicle k travels from node i to node j in time period t, x = 1 ; otherwise, x = 0

dvar float+ tq[nodes][nodes][vehicles][periods]; //Quantity of the blood product transported by vehicle k trough arc (i, j) in time period t

dvar float+ Q[periods]; //Inventory of the blood product at the blood center in time period t after receiving the quantity produced in time period t 1, allocating the delivered quantity to hospitals and disposing of the expired quantity

dvar float+ W[periods]; //Quantity of expired blood product at the blood center in time period t

dvar float+ I[ i in hospitals][t in periods]; //Inventory level of the blood product at hospital i in time period t after receiving the delivered quantity and usage and i > 0

dvar float+ G[i in hospitals][t in periods]; //Shortage quantity at hospital i in time period t
   

//Model

//Objective Function

dexpr float FirstObjectiveFunction = sum(i in hospitals , k in vehicles , t in periods) fc[k]*x[0][i][k][t]
+sum(i in nodes , j in nodes , k in vehicles , t in periods) vc[k]*dis[i][j]*tq[i][j][k][t]
+sum(t in periods) (h[0]*Q[t]+sum(i in hospitals) h[i]*I[i][t])
+sum(t in periods) w*W[t]
+sum(i in hospitals , t in periods) e[i][t]*G[i][t]
+sum(i in hospitals , k in vehicles , t in periods) pc[i]*pq[i][k][t];

minimize FirstObjectiveFunction;


//Constraints

subject to{

forall(t in periods) cons01: p[t]<=M[t];

forall(t in periods : 2<=t) cons02: Q[t]==Q[t-1]+p[t-1]-sum(i in hospitals , k in vehicles) dq[i][k][t]-W[t];

forall(t in periods : z<t) cons03: W[t]>=Q[t-z]-sum(i in hospitals , k in vehicles , s in periods : (t-z+1)<=s<=(t-1)) dq[i][k][s]- sum(s in periods : (t-z+1)<=s<=(t-1)) W[s];

forall(t in periods : 0<t<=z) cons04: W[t]==0;

forall(t in periods) cons05: Q[t]<=l[0];

forall(t in periods , i in hospitals : 2<=t) cons06: I[i][t]==I[i][t-1]+sum(k in vehicles) dq[i][k][t-1]-sum(k in vehicles) pq[i][k][t-1]-u[i][t-1];


forall(t in periods , i in hospitals) cons07: I[i][t]<=l[i];

forall(t in periods , i in hospitals) cons08: G[i][t]>=u[i][t]-I[i][t];

forall(t in periods , i in hospitals) cons09: sum(k in vehicles) y[i][k][t]<=1;

forall(t in periods) cons10: sum(k in vehicles) y[0][k][t]==K;

forall(t in periods , i in hospitals , k in vehicles) cons11: dq[i][k][t]<=l[i]*y[i][k][t];

forall(t in periods) cons12: sum(i in hospitals , k in vehicles) dq[i][k][t]<=Q[t];

forall(j in nodes , k in vehicles , t in periods) cons13: sum(i in nodes : i!=j) x[i][j][k][t]==y[j][k][t];

forall(i in nodes , k in vehicles , t in periods) cons14: sum(j in nodes : j!=i) x[i][j][k][t]==y[i][k][t];

forall( i in nodes , j in nodes , k in vehicles , t in periods) cons15: tq[i][j][k][t]<=cv[k]*x[i][j][k][t];

forall(t in periods , k in vehicles , s in ss: 2<=card(sub[s])) cons16: sum(i,j in sub[s]) x[i][j][k][t] <= card(sub[s])-1;

forall(i in hospitals , k in vehicles , t in periods) cons17: sum(j in nodes) tq[j][i][k][t]-dq[i][k][t]+pq[i][k][t]==sum(j in nodes) tq[i][j][k][t];

forall(i in hospitals , t in periods) cons18: sum(k in vehicles) pq[i][k][t]<=I[i][t];

forall(i in nodes , k in vehicles , t in periods) cons19: x[i][i][k][t]==tq[i][0][k][t]==0;

forall(i in hospitals , k in vehicles , t in periods) cons20: y[0][k][t]>=y[i][k][t];

}