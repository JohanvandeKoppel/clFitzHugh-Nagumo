//
//  Initial_values.cpp
//  clFitzHugh-Nagumo
//
//  Created by Johan Van de Koppel on 09/09/15.
//  Copyright (c) 2015 Johan Van de Koppel. All rights reserved.
//

#include <stdio.h>

////////////////////////////////////////////////////////////////////////////////
// A point as initial value
////////////////////////////////////////////////////////////////////////////////

void PointInit(float* data, int x_siz, int y_siz, int type)
{
    for(int i=0;i<y_siz;i++)
    {
        for(int j=0;j<x_siz;j++)
        {
            //for every element find the correct initial
            //value using the conditions below
            if(i<(y_siz/2-9)||i>(y_siz/2+10)||j<(x_siz/2-9)||j>(x_siz/2+10))
            {
                if(type==VOLTAGE)
                {
                    data[i*y_siz+j]=-0.53f;
                }
                else if(type==RECOVERY)
                {
                    data[i*y_siz+j]=-0.20f;
                }
            }
            else
            {
                if(type==VOLTAGE)
                {
                    data[i*y_siz+j]=0.53f;
                }
                else if(type==RECOVERY)
                {
                    data[i*y_siz+j]=0.38f;
                }
            }
        }
    }
} // End PointInit


////////////////////////////////////////////////////////////////////////////////
// Allocates a matrix with random float entries
////////////////////////////////////////////////////////////////////////////////

void randomInit (float* data, int x_siz, int y_siz, int type)
{
    int i,j;
    for(i=0;i<y_siz;i++)
    {
        for(j=0;j<x_siz;j++)
        {
            //assigning the first row last row and
            //first column last column as zeroes
            
            if(i==0||i==y_siz-1||j==0||j==x_siz-1)
                data[i*y_siz+j]=0.0f;
            else
            {
                //for every other element find the correct initial
                //value using the conditions below
                if((rand() / (float)RAND_MAX)<(float)Frac)
                //if( (i<(y_siz/2+3)) && (i>(y_siz/2-3)) && (j<(x_siz/2+3)) && (j>(x_siz/2-3)) )
                {
                    if(type==VOLTAGE)
                        data[i*y_siz+j] = (float)-0.53f;
                    else if(type==RECOVERY)
                        data[i*y_siz+j] = (float)-0.20f;
                }
                else
                {
                    if(type==VOLTAGE)
                        data[i*y_siz+j] = (float)0.53f;
                    else if(type==RECOVERY)
                        data[i*y_siz+j] = (float)0.38f;
                }

            }
        }
    }
} // End randomInit

////////////////////////////////////////////////////////////////////////////////
// Prints the model name and additional info
////////////////////////////////////////////////////////////////////////////////

void Print_Label()
{
    //system("clear");
    printf("\n");
    printf(" * * * * * * * * * * * * * * * * * * * * * * * * * * * * * \n");
    printf(" * The FitzHugh-Nagumo model                             * \n");
    printf(" * OpenCL implementation : Johan van de Koppel, 2016     * \n");
    printf(" * Following a model by FitzHugh 1955                    * \n");
    printf(" * * * * * * * * * * * * * * * * * * * * * * * * * * * * * \n\n");
    
} // Print_Label
