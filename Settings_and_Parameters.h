//
//  clFitzHugh-Nagumo settings and parameters
//
//  Created by Johan Van de Koppel on 03-09-14.
//  Copyright (c) 2014 Johan Van de Koppel. All rights reserved.
//

// Compiler directives
#define ON              1
#define OFF             0

#define Print_All_Devices OFF

#define Device_No       1   // 0: CPU; 1: Intel 4000; 2: Nvidia GT 650M
#define ProgressBarWidth 45

#define WorkGroupSize   16
#define DomainSize      1024

// Thread block size
#define Block_Size_X	(WorkGroupSize)
#define Block_Size_Y	(WorkGroupSize)

// Number of blox
/* I define the Block_Number_ensions of the matrix as product of two numbers
Makes it easier to keep them a multiple of something (16, 32) when using CUDA*/
#define Block_Number_X	(DomainSize/WorkGroupSize)
#define Block_Number_Y	(DomainSize/WorkGroupSize)

// Matrix Block_Number_ensions
// (chosen as multiples of the thread block size for simplicity)
#define Grid_Width  (Block_Size_X * Block_Number_X)			// Matrix A width
#define Grid_Height (Block_Size_Y * Block_Number_Y)			// Matrix A height
#define Grid_Size (Grid_Width*Grid_Height)                  // Grid Size

// DIVIDE_INTO(x/y) for integers, used to determine # of blocks/warps etc.
#define DIVIDE_INTO(x,y) (((x) + (y) - 1)/(y))

//      Parameters		   Original value    Explanation and Units
#define Epsilon   0.3           // 0.075 Non-dimensional model parameter
#define a1        1.4           // 1.485 Non-dimensional model parameter
#define a0        0.0           // 0     Non-dimensional model parameter
#define Delta     2             // 3     Non-dimensional model parameter

#define dX	      0.5           // 0.5   Spatial scale
#define dY	      0.5           // 0.5   Spatial scale

#define Frac      0.01          // 0.01   - Fraction of area that is covered
#define dT        0.01          // 0.01   - The timestep of the simulation
#define EndTime	  2100          // 3000   - hours     The time at which the simulation ends
#define NumFrames 300           // Number of times during the simulation that the data is stored
#define	MAX_STORE (NumFrames+1) //

// Name definitions
#define VOLTAGE     101
#define RECOVERY	102


