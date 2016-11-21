#include "Settings_and_Parameters.h"

////////////////////////////////////////////////////////////////////////////////
// Laplacation operator definition, to calculate diffusive fluxes
////////////////////////////////////////////////////////////////////////////////

float d2_dxy2(__global float* C, int row, int column)
{
    float retval;
    float dx = (float)dX;
    float dy = (float)dY;
    
    int current = row * Grid_Width + column;
    int left    = row * Grid_Width + column-1;
    int right   = row * Grid_Width + column+1;
    int top     = (row-1) * Grid_Width + column;
    int bottom  = (row+1) * Grid_Width + column;
    
    retval = ( C[left] + C[right]  - 2 * C[current] )/dx/dx +
             ( C[top]  + C[bottom] - 2 * C[current] )/dy/dy;
    
    return retval;
}

////////////////////////////////////////////////////////////////////////////////
// Simulation kernel
////////////////////////////////////////////////////////////////////////////////

__kernel void SimulationKernel (__global float* u, __global float* v)
{
    
	float d2udxy2, d2vdxy2;
	
    size_t current  = get_global_id(0);
    int    row		= floor((float)current/(float)Grid_Width);
    int    column	= current%Grid_Width;

	if (row > 0 && row < Grid_Height-1 && column > 0 && column < Grid_Height-1)
    {
        
        d2udxy2 = d2_dxy2(u, row, column);
        d2vdxy2 = d2_dxy2(v, row, column);
        
		u[current]=u[current]+(u[current] - u[current]*u[current]*u[current] - v[current] + d2udxy2)*dT;
		v[current]=v[current]+(Epsilon*(u[current] - a1*v[current] - a0) + Delta*d2vdxy2)*dT;
        
    }
    
    //barrier(CLK_LOCAL_MEM_FENCE);
    
	// HANDLE Boundaries
	if(row==0)
		//do copy of first row = second last row
    {
        u[current]=u[(Grid_Height-2)*Grid_Width+column];
        v[current]=v[(Grid_Height-2)*Grid_Width+column];
    }
    
	else if(row==Grid_Height-1)
		//do copy of last row = second row
    {
        u[current]=u[1*Grid_Width+column];
        v[current]=v[1*Grid_Width+column];
    }
    else if(column==0)
    {
        u[current] = u[row * Grid_Width + Grid_Width - 2];
        v[current] = v[row * Grid_Width + Grid_Width - 2];
    }
    else if(column==Grid_Width-1)
    {
        u[current] = u[row * Grid_Width + 1];
        v[current] = v[row * Grid_Width + 1];
    }
	
} // End SimulationKernel

