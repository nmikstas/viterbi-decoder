#include <ap_fixed.h>
#include <stdlib.h>
#include <stdio.h>
#include "Viterbi.h"

int main()
{
    //Delay line for matching output with input.
    EncInData delayLine[DELAY_LENGTH];

    //Random error generation variables.
    uint8_t errorByte = 0;
    ErrBit ebit = 0;

    //Data for input and output of encoder.
    EncInData  encInData  = 0;
    EncOutData encOutData = 0;

    //Data for input and output of decoder.
    DecInData  decInData  = 0;
    DecOutData decOutData = 0;

    //Encoder history.
    EncInData unencoded  = 0;
    EncInData unencoded1 = 0;
    EncInData unencoded2 = 0;

    //Indicate if delay line is equal to output.
    bool matched = false;

    //Zero out the delay line.
    for(int ii = 0; ii < DELAY_LENGTH; ii++) delayLine[ii] = 0;

    std::cout << "\n----------PHASE 1----------\n" << std::endl;

    //Test phase 1.  No error injection.
    for(int i = 0; i < TEST_RUNS_PHASE1; i++)
    {
        //Randomly generate an input bit.
        encInData = rand();

        //increment encoder history.
        unencoded2 = unencoded1;
        unencoded1 = unencoded;
        unencoded = encInData;

        //Encode input data.
        decInData = unencoded ^ unencoded2;
        decInData <<= 1;
        decInData |= unencoded ^ unencoded1 ^ unencoded2;

        //Update delay line.
        for(int j = DELAY_LENGTH - 1; j > 0; j--) delayLine[j] = delayLine[j-1];
        delayLine[0] = encInData;

        //Send encoded data to the decoder.
        doDecode(decInData, &decOutData);

        if(delayLine[DELAY_LENGTH - 1] == decOutData) matched = true;
        else matched = false;

        //Display results.
        std::cout << "Bit: " << i << " Encoder in data: " << encInData << " Decoder in data: "
                  << decInData << " Decoder out data: " << decOutData << " Delay line out: "
                  << delayLine[DELAY_LENGTH - 1];

        if(!matched) std::cout << " ***MISMATCH***";
        std::cout << std::endl;
    }

    std::cout << "\n----------PHASE 2----------\n" << std::endl;

    //Test phase 2.  Error injection.
    for(int i = 0; i < TEST_RUNS_PHASE2; i++)
    {
        //Randomly generate an input bit.
        encInData = rand();

        //Randomly generate an error bit.
        errorByte = rand();
        if(errorByte > ERROR_THRESHOLD) ebit = 1;
        else ebit = 0;

        //increment encoder history.
        unencoded2 = unencoded1;
        unencoded1 = unencoded;
        unencoded = encInData;

        //Encode input data.
        decInData = unencoded ^ unencoded2;
        decInData <<= 1;
        decInData |= unencoded ^ unencoded1 ^ unencoded2 ^ ebit;

        //Update delay line.
        for(int j = DELAY_LENGTH - 1; j > 0; j--) delayLine[j] = delayLine[j-1];
        delayLine[0] = encInData;

        //Send encoded data to the decoder.
        doDecode(decInData, &decOutData);

        if(delayLine[DELAY_LENGTH - 1] == decOutData) matched = true;
        else matched = false;

        //Display results.
        std::cout << "Bit: " << i << " Encoder in data: " << encInData << " Decoder in data: "
                  << decInData << " Decoder out data: " << decOutData << " Delay line out: "
                  << delayLine[DELAY_LENGTH - 1];

        if(!matched) std::cout << " ***MISMATCH***";
        if(ebit) std::cout << " ***ERROR INJECTED***";
        std::cout << std::endl;
    }

    return 0;
}
