#ifndef VITERBI_H_
#define VITERBI_H_

#include "ap_fixed.h"

#define TEST_RUNS_PHASE1 50
#define TEST_RUNS_PHASE2 100
#define DELAY_LENGTH 18
#define ERROR_THRESHOLD 214

#define WINDOW_LENGTH 16 //Length of survivor window.
#define ONE_BIT   1     //One bit data.
#define TWO_BIT   2     //Two bit data.
#define THREE_BIT 3     //Three bit data.
#define FOUR_BIT  4     //Four bit data.

#define DEPTH4    4     //Four element array depth.

typedef ap_uint<ONE_BIT>   DecOutData, BranchDirection, EncInData, ErrBit;  //1 bit data.
typedef ap_uint<TWO_BIT>   InData, State, EncOutData, DecInData;            //2 bit data.
typedef ap_uint<THREE_BIT> BranchDistanceType, EncHistory;                  //3 bit data.
typedef ap_uint<FOUR_BIT>  SurvivorElement, DistanceType;                   //4 bit data.

class ViterbiDecoder
{
    public:
        ViterbiDecoder();
        void decode(DecInData indat, DecOutData *outdat);

    private:
        SurvivorElement survivorWindow[WINDOW_LENGTH];
        SurvivorElement survivors;
        SurvivorElement backtrackSurvivors;

        DistanceType distance[DEPTH4];
        DistanceType globalDistance[DEPTH4];

        InData inData;

        BranchDistanceType upperBranchDistance[DEPTH4];
        BranchDistanceType lowerBranchDistance[DEPTH4];
        BranchDistanceType branchDistance[DEPTH4];
        BranchDistanceType minimumBranch;

        State state;

        BranchDirection branchDirection;
};

//Function that accesses the Viterbi decoder class.
void doDecode(DecInData indat, DecOutData *outdat);

#endif
