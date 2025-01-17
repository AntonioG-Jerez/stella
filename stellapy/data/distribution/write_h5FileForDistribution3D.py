  
import numpy as np
import os, h5py, pathlib 
from stellapy.utils.decorators.verbose import noverbose 
from stellapy.utils.files.get_filesInFolder import get_filesInFolder  
from stellapy.data.input.read_inputFile import read_vmecFileNameFromInputFile
from stellapy.data.input.read_inputFile import read_linearNonlinearFromInputFile
from stellapy.data.geometry.read_output import read_outputFile as read_outputFileForGeometry
from stellapy.data.paths.load_pathObject import create_dummyPathObject   
from stellapy.data.output.read_outputFile import read_outputFile, read_netcdfVariables 
from stellapy.data.utils.get_indicesAtFixedStep import get_indicesAtFixedStep

################################################################################
#                       WRITE THE DISTRIBUTION TO AN H5 FILE
################################################################################

@noverbose
def write_h5FileForDistribution3D(folder, dt=10):      
    
    # Time step
    dt = int(dt) if int(dt)==dt else dt   
     
    # Get the input files
    input_files = get_filesInFolder(folder, end=".in")
    input_files = [i for i in input_files if os.path.isfile(i.with_suffix('.out.nc'))]
    if input_files==[]: return 
 
    # Iterate through the input files  
    for input_file in input_files: 
        
        # Processing status
        status = "    ("+str(input_files.index(input_file)+1)+"/"+str(len(input_files))+")  " if len(input_files)>1 else "   "
        
        # Only write this data for nonlinear simulations 
        if read_linearNonlinearFromInputFile(input_file)[1]:  
            
            # Path of the new file 
            netcdf_file = input_file.with_suffix(".out.nc")
            distribution_file = input_file.with_suffix(".dt"+str(dt)+".distribution3D")   
        
            # If the file doesn't exist, check whether gvmus and gzvs were written
            if not os.path.isfile(distribution_file): 
                netcdf_data  = read_outputFile(netcdf_file)  
                if "gvmus" not in netcdf_data.variables.keys() or "gzvs" not in netcdf_data.variables.keys():
                    continue
            
            # Check whether the distribution file is older than the simulation
            outputFileHasChanged = False
            if os.path.isfile(distribution_file):  
                if netcdf_file.stat().st_mtime > distribution_file.stat().st_mtime:
                    outputFileHasChanged = True 
        
            # Notify that the file already existed   
            if os.path.isfile(distribution_file) and not outputFileHasChanged:
                print(status+"The 3D distribution file already exists:", distribution_file.parent.name+"/"+distribution_file.name)
                continue
        
            # If the output file changed, then append to the h5 file
            elif os.path.isfile(distribution_file) and outputFileHasChanged:
                
                # Check whether the output file (*.out.nc) contains extra time points
                netcdf_data  = read_outputFile(netcdf_file)   
                vec_time     = read_netcdfVariables('vec_time', netcdf_data) 
                netcdf_data.close()  
                
                # Edit the time vector in the output file
                indices  = get_indicesAtFixedStep(vec_time, dt)
                vec_time = vec_time[indices]
                vec_time = [round(n, 8) for n in vec_time]
                tlast_outputfile = vec_time[-1]  
                
                # Read the data in the h5 file            
                with h5py.File(distribution_file, 'r') as f: 
                    vec_time_h5file = f['vec_time'][()]
                    g_vs_tsz_h5file = f['g_vs_tsz'][()] 
                    g_vs_tsmu_h5file = f['g_vs_tsmu'][()] 
                    g_vs_tsvpa_h5file = f['g_vs_tsvpa'][()] 
                    tlast_h5file = vec_time_h5file[-1]
            
                # If the output file (*.out.nc) contains extra time steps, append to the h5 file 
                if tlast_outputfile > tlast_h5file: 
                    index_tlast = np.argwhere(tlast_h5file < vec_time)[0][0] 
                    g_vs_tsz, g_vs_tsmu, g_vs_tsvpa, vec_time = read_distribution3D(dt, netcdf_file, input_file) 
                    vec_time = np.append(vec_time_h5file, vec_time[index_tlast:], axis=0)  
                    g_vs_tsz = np.append(g_vs_tsz_h5file, g_vs_tsz[index_tlast:,:], axis=0)
                    g_vs_tsmu = np.append(g_vs_tsmu_h5file, g_vs_tsmu[index_tlast:,:], axis=0)  
                    g_vs_tsvpa = np.append(g_vs_tsvpa_h5file, g_vs_tsvpa[index_tlast:,:], axis=0)  
            
                # If the output file has the same time steps, touch the text file
                elif tlast_outputfile <= tlast_h5file:
                    print(status+"The 3D distribution file is up to date:", distribution_file.parent.name+"/"+distribution_file.name)  
                    os.system("touch "+str(distribution_file))
                    continue
                
            # Otherwise write the file from scratch
            elif not os.path.isfile(distribution_file):    
                
                # Read the potential versus time from the output file
                g_vs_tsz, g_vs_tsmu, g_vs_tsvpa, vec_time = read_distribution3D(dt, netcdf_file, input_file) 
                    
            # Create the new h5 file 
            with h5py.File(distribution_file, 'w') as h5_file: 
                h5_file.create_dataset("vec_time", data=vec_time) 
                h5_file.create_dataset("g_vs_tsz", data=g_vs_tsz) 
                h5_file.create_dataset("g_vs_tsmu", data=g_vs_tsmu) 
                h5_file.create_dataset("g_vs_tsvpa", data=g_vs_tsvpa) 
        
            # Notify that we finished creating the file
            if outputFileHasChanged: print(status+"   ---> The 3D distribution file is updated as " +  distribution_file.parent.name+"/"+distribution_file.name)   
            if not outputFileHasChanged:  print(status+"   ---> The 3D distribution file is saved as " +  distribution_file.parent.name+"/"+distribution_file.name)  
        
    return 

#---------------------------------------------------
def read_distribution3D(dt, netcdf_file, input_file):
    
    # Read the geometry data in the output file
    vmec_filename = read_vmecFileNameFromInputFile(input_file)
    nonlinear = read_linearNonlinearFromInputFile(input_file)[1]
    path = create_dummyPathObject(input_file, vmec_filename, nonlinear)
    geometry = read_outputFileForGeometry(path) 
    vpa_weights = geometry["vpa_weights"] 
    mu_weights = geometry["mu_weights"] 
    dl_over_B = geometry["dl_over_B"]  
    
    # Get the distribution data from the output file
    netcdf_data  = read_outputFile(netcdf_file)  
    g_vs_tsmuvpa = read_netcdfVariables('g_vs_tsmuvpa', netcdf_data) 
    g_vs_tsvpaz  = read_netcdfVariables('g_vs_tsvpaz', netcdf_data) 
    vec_time     = read_netcdfVariables('vec_time', netcdf_data) 
    netcdf_data.close()
    
    # Get the data at every <dt> timestep
    indices = get_indicesAtFixedStep(vec_time, dt)
    g_vs_tsmuvpa = g_vs_tsmuvpa[indices] 
    g_vs_tsvpaz = g_vs_tsvpaz[indices] 
    vec_time = vec_time[indices]
    
    # Get the dimensions  
    dim_time, dim_species, dim_mu, dim_vpa = np.shape(g_vs_tsmuvpa) 
    dim_time, dim_species, dim_vpa, dim_z = np.shape(g_vs_tsvpaz) 

    # Calculate the 3D distribution functions
    g_vs_tsz = np.zeros((dim_time, dim_species, dim_z)) 
    g_vs_tsmu = np.zeros((dim_time, dim_species, dim_mu)) 
    g_vs_tsvpa = np.zeros((dim_time, dim_species, dim_vpa))  
    
    # Sum over (vpa,mu,z)
    for vpa in range(dim_vpa): 
        for mu in range(dim_mu):
            for z in range(dim_z): 
                product = g_vs_tsmuvpa[:,:,mu,vpa]*mu_weights[z,mu]*vpa_weights[vpa]*dl_over_B[z] 
                g_vs_tsz[:,:,z] += product  
                g_vs_tsmu[:,:,mu] += product  
                g_vs_tsvpa[:,:,vpa] += product  
                
    return g_vs_tsz, g_vs_tsmu, g_vs_tsvpa, vec_time
                            
################################################################################
#                     USE THESE FUNCTIONS AS A MAIN SCRIPT                     #
################################################################################
if __name__ == "__main__":  
    folder = pathlib.Path("/home/hanne/CIEMAT/RUNS/TEST_NEW_GUI")   
    write_h5FileForDistribution3D(folder) 
    