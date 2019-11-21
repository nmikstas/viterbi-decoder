#include "Viterbi.h"

void doDecode(DecInData indat, DecOutData *outdat)
{
    static ViterbiDecoder viterbiDecoder; //Instantiate decoder object.
    viterbiDecoder.decode(indat, outdat);
}

//Constructor to initialize the variables in the decoder.
ViterbiDecoder::ViterbiDecoder():survivors(0), backtrackSurvivors(0),
        inData(0), minimumBranch(0), state(0), branchDirection(0)
{
    //Initialize the survivor memory.
    for(int i = 0; i < WINDOW_LENGTH; i++) survivorWindow[i] = 0;

    //Initialize remaining variables.
    for(int i = 0; i < DEPTH4; i++)
    {
        distance[i] = 0;
        upperBranchDistance[i] = 0;
        globalDistance[i] = !i ? 0 : 2;
        lowerBranchDistance[i] = 0;
        branchDistance[i] = 0;
    }
}

//Add a bit to be decoded.
void ViterbiDecoder::decode(DecInData indat, DecOutData *outdat)
{
    inData = indat;

    //Calculate distances.
    switch(inData)
    {
        case 0:
            distance[0] = 0;
            distance[1] = 1;
            distance[2] = 1;
            distance[3] = 2;
        break;

        case 1:
            distance[0] = 1;
            distance[1] = 0;
            distance[2] = 2;
            distance[3] = 1;
        break;

        case 2:
            distance[0] = 1;
            distance[1] = 2;
            distance[2] = 0;
            distance[3] = 1;
        break;

        case 3:
            distance[0] = 2;
            distance[1] = 1;
            distance[2] = 1;
            distance[3] = 0;
        break;

        default:  //Invalid case.
        break;
    }

    //Calculate distances for the upper and lower branches.
    for(int i = 0; i < 4; i++)
    {
        switch(i)
        {
            case 0:
                upperBranchDistance[i] = distance[0] + globalDistance[0];
                lowerBranchDistance[i] = distance[3] + globalDistance[2];
            break;

            case 1:
                upperBranchDistance[i] = distance[3] + globalDistance[0];
                lowerBranchDistance[i] = distance[0] + globalDistance[2];
            break;

            case 2:
                upperBranchDistance[i] = distance[1] + globalDistance[1];
                lowerBranchDistance[i] = distance[2] + globalDistance[3];
            break;

            case 3:
                upperBranchDistance[i] = distance[2] + globalDistance[1];
                lowerBranchDistance[i] = distance[1] + globalDistance[3];
            break;

            default: //Invalid case.
            break;
        }

        //Select the surviving branch and fill appropriate value into the survivor window.
        if(upperBranchDistance[i] <= lowerBranchDistance[i])
        {
            branchDistance[i] = upperBranchDistance[i];
            survivors  &= ~(1 << i);
        }
        else
        {
            branchDistance[i] = lowerBranchDistance[i];
            survivors |= (1 << i);
        }
    }

    survivorWindow[0] = survivors;

    //Find the minimum branch distance and the ending state.
    minimumBranch = branchDistance[0];
    state = 0;

    for(int i = 1; i < 4; i++)
    {
        if(branchDistance[i] < minimumBranch)
        {
            minimumBranch = branchDistance[i];
            state = i;
        }
    }

    //Subtract the minimum distance to avoid overflow.
    for(int i = 0; i < 4; i++)
    {
        globalDistance[i] = branchDistance[i] - minimumBranch;
    }

    //Backtrack the survivor window from the most likely state.
    for(int i = 0; i < WINDOW_LENGTH; i++)
    {
        backtrackSurvivors = survivorWindow[i];
        branchDirection = backtrackSurvivors[state];

        switch(state)
        {
            case 0:
            case 1:
                if(!branchDirection) state = 0;
                else state = 2;
            break;

            case 2:
            case 3:
                if(!branchDirection) state = 1;
                else state = 3;
            break;

            default: //Invalid state.
            break;
        }
    }

    //Shift the survivor window values.
    for(int i = WINDOW_LENGTH - 1; i > 0; i--)
    {
        survivorWindow[i] = survivorWindow[i - 1];
    }

    //Generate output.
    *outdat = branchDirection;
}
