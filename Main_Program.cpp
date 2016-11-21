//
//  Main_Program.cpp
//
//  Created by Johan Van de Koppel on 03-09-14.
//  Copyright (c) 2014 Johan Van de Koppel. All rights reserved.
//

#include <stdio.h>
#include <sys/time.h>
#include <iostream>
#include <math.h>

#include "Settings_and_Parameters.h"
#include "Device_Utilities.h"
#include "Initial_values.h"

#ifdef __APPLE__
#include <OpenCL/opencl.h>
#else
#include <CL/cl.h>
#endif

#define MAX_SOURCE_SIZE (0x100000)

////////////////////////////////////////////////////////////////////////////////
// Main program code for Mussels
////////////////////////////////////////////////////////////////////////////////

int main()
{
    
    /*----------Constant and variable definition------------------------------*/
    
	unsigned int Grid_Memory = sizeof(float) * Grid_Size;
	unsigned int size_storegrid = Grid_Width * Grid_Height * MAX_STORE;
	unsigned int mem_size_storegrid = sizeof(float) * size_storegrid;
    
    /*----------Defining and allocating memeory on host-----------------------*/
    
    // Defining and allocating the memory blocks for P, W, and O on the host (h)
    float* h_V1 = (float *)malloc(Grid_Width*Grid_Height*sizeof(float));
	float* h_V2 = (float *)malloc(Grid_Width*Grid_Height*sizeof(float));
	
    // Defining and allocating storage blocks for P, W, and O on the host (h)
    float* h_store_V1=(float*) malloc(mem_size_storegrid);
	float* h_store_V2=(float*) malloc(mem_size_storegrid);
    
    /*----------Initializing the host arrays----------------------------------*/
    
    srand(50); // Seeding the random number generator
    
	//randomInit(h_V1, Grid_Width, Grid_Height, VOLTAGE);
	//randomInit(h_V2, Grid_Width, Grid_Height, RECOVERY);
    
    PointInit(h_V1, Grid_Width, Grid_Height, VOLTAGE);
    PointInit(h_V2, Grid_Width, Grid_Height, RECOVERY);
    
    /*----------Printing info to the screen ----------------------------------*/

    Print_Label();
    
	printf(" Current grid dimensions: %d x %d cells\n\n",
           Grid_Width, Grid_Height);
    
    /*----------Setting up the device and the kernel--------------------------*/
    
    cl_device_id* devices;
    cl_int err;
    
    cl_context context = CreateGPUcontext(devices);
    
    // Print the name of the device that is used
    printf(" Implementing PDE on device %d: ", Device_No);
    print_device_info(devices, (int)Device_No);
    printf("\n");
    
    // Create a command queue on the device
    cl_command_queue command_queue = clCreateCommandQueue(context, devices[Device_No], 0, &err);
    
    /*----------Create Buffer Objects for A and M on the device-------------*/
    
	cl_mem d_V1 = clCreateBuffer(context, CL_MEM_READ_WRITE, Grid_Memory, NULL, &err);
	cl_mem d_V2 = clCreateBuffer(context, CL_MEM_READ_WRITE, Grid_Memory, NULL, &err);
    
	/* Copy input data to the memory buffer */
	err = clEnqueueWriteBuffer(command_queue, d_V1, CL_TRUE, 0, Grid_Width*Grid_Height*sizeof(float), h_V1, 0, NULL, NULL);
	err = clEnqueueWriteBuffer(command_queue, d_V2, CL_TRUE, 0, Grid_Width*Grid_Height*sizeof(float), h_V2, 0, NULL, NULL);

    /*----------Building the PDE kernel---------------------------------------*/
    
    cl_program program = BuildKernelFile("Computing_Kernel.cl", context, &devices[Device_No], &err);
    if (err!=0)  printf(" > Compile Program Error number: %d \n\n", err);
    
    /* Create OpenCL kernel */
    cl_kernel kernel = clCreateKernel(program, "SimulationKernel", &err);
    if (err!=0) printf(" > Create Kernel Error number: %d \n\n", err);
    
	/* Set OpenCL kernel arguments */
	err =       clSetKernelArg(kernel, 0, sizeof(cl_mem), (void *)&d_V1);
	err = err + clSetKernelArg(kernel, 1, sizeof(cl_mem), (void *)&d_V2);
    
    if (err!=0) { printf(" > Memory binding error: %d \n\n", err); exit(1); }
    
    /*----------Set op timer and progress bar---------------------------------*/

    /* create and start timer */
    struct timeval Time_Measured;
    gettimeofday(&Time_Measured, NULL);
    double Time_Begin=Time_Measured.tv_sec+(Time_Measured.tv_usec/1000000.0);

    /* Progress bar initiation */
    int RealBarWidth=std::min((int)NumFrames,(int)ProgressBarWidth);
    int BarCounter=0;
    double BarThresholds[RealBarWidth];
    for (int i=1;i<RealBarWidth;i++)
        { BarThresholds[i] = (double)(i+1)/(double)RealBarWidth*(double)NumFrames; };
    
    /* Print the reference bar */
    printf(" Progress: [");
    for (int i=0;i<RealBarWidth;i++) { printf("-"); }
    printf("]\n");
    fprintf(stderr, "           >");
    
    /*----------Kernel parameterization---------------------------------------*/
    
    size_t global_item_size = Grid_Width*Grid_Height;
    size_t local_item_size = Block_Size_X*Block_Size_Y;

    /*----------Calculation loop----------------------------------------------*/
	for (int Counter=0;Counter<NumFrames;Counter++)
    {
        for (int Runtime=0;Runtime<floor((float)EndTime/NumFrames/dT);Runtime++)
        {
            /* Execute OpenCL kernel as data parallel */
            err = clEnqueueNDRangeKernel(command_queue, kernel, 1, NULL,
                                         &global_item_size, &local_item_size, 0, NULL, NULL);

            if (err!=0) { printf(" > Kernel Error number: %d \n\n", err); exit(-10);}

        }
        
        /* Transfer result to host */
        err  = clEnqueueReadBuffer(command_queue, d_V1, CL_TRUE, 0, Grid_Width*Grid_Height*sizeof(float), h_V1, 0, NULL, NULL);
        err |= clEnqueueReadBuffer(command_queue, d_V2, CL_TRUE, 0, Grid_Width*Grid_Height*sizeof(float), h_V2, 0, NULL, NULL);

        if (err!=0) printf("Read Buffer Error: %d\n\n", err);
        
        //Store values at this frame.
        memcpy(h_store_V1+(Counter*Grid_Size),h_V1,Grid_Memory);
        memcpy(h_store_V2+(Counter*Grid_Size),h_V2,Grid_Memory);
        
        // Progress the progress bar if time
        if ((float)(Counter+1)>=BarThresholds[BarCounter]) {
            fprintf(stderr,"*");
            BarCounter = BarCounter+1;}
            
    }
    
    printf("<\n\n"); 
    
    /*---------------------Report on time spending----------------------------*/
    gettimeofday(&Time_Measured, NULL);
    double Time_End=Time_Measured.tv_sec+(Time_Measured.tv_usec/1000000.0);
	printf(" Processing time: %4.3f (s) \n", Time_End-Time_Begin);
    
    /*---------------------Write to file now----------------------------------*/
    
    // The location of the code is obtain from the __FILE__ macro
    const std::string SourcePath (__FILE__);
    const std::string PathName = SourcePath.substr (0,SourcePath.find_last_of("/")+1);
    const std::string DataPath = PathName + "Output.dat";
    
	FILE * fp=fopen(DataPath.c_str(),"wb");

    int width_matrix = Grid_Width;
    int height_matrix = Grid_Height;
    int NumStored = NumFrames;
    float Length = dX*(float)Grid_Width;
    int EndTimeVal = EndTime;

	// Storing parameters
	fwrite(&width_matrix,sizeof(int),1,fp);
	fwrite(&height_matrix,sizeof(int),1,fp);
    fwrite(&Length,sizeof(float),1,fp);
	fwrite(&NumStored,sizeof(int),1,fp);
	fwrite(&EndTimeVal,sizeof(int),1,fp);
	
	for(int store_i=0;store_i<NumFrames;store_i++)
    {
		fwrite(&h_store_V1[store_i*Grid_Size],sizeof(float),Grid_Size,fp);
		fwrite(&h_store_V2[store_i*Grid_Size],sizeof(float),Grid_Size,fp);
    }
	
	printf("\r Simulation results saved! \n\n");
    
	fclose(fp);
    
	/*---------------------Clean up memory------------------------------------*/
	
    // Freeing host space
    free(h_V1);
	free(h_V2);
    
	free(h_store_V1);
	free(h_store_V2);
 
	// Freeing kernel and block space
	err = clFlush(command_queue);
	err = clFinish(command_queue);
	err = clReleaseKernel(kernel);
	err = clReleaseProgram(program);
	err = clReleaseMemObject(d_V1);
	err = clReleaseMemObject(d_V2);
	err = clReleaseCommandQueue(command_queue);
	err = clReleaseContext(context);
    free(devices);
    
    #if defined(__APPLE__) && defined(__MACH__)
        // system("say Simulation finished");
    #endif

	return 0;
}


