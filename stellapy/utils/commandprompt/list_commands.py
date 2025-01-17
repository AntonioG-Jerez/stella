"""
#===============================================================================
#                          LIST ALL THE STELLAPY COMMANDS                      #
#===============================================================================

List all the stellapy commands. 

"""

#!/usr/bin/python3  
import sys, os

# Personal modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)).split("stellapy/")[0])  
from stellapy.utils.commandprompt.bash import Bash

#===============================================================================
#                          LIST ALL THE STELLAPY COMMANDS                      #
#===============================================================================

def list_commands(width=90):
    
    # Start 
    print("\n"+"".center(width,"="))
    print("\033[1m"+"STELLAPY".center(width," ")+"\033[0m")
    print("".center(width,"="))   
    print("""
    In order to use the stellapy scripts and functions one can call the functions 
    directly from the python3 interactive prompt, or one can use the bash commands 
    defined in stellapy/source.sh directly from the command prompt. A list of possible
    stellapy functions that work as bash commands is shown through the command:
        >> stellapy
    
    These commands can be used in the same way as bash commands, a list of options 
    is shown for each commands by performing:
        >> command -h
    
    Developed by Hanne Thienpondt. 
    01/09/2022
    """)
    
    # Start 
    print("\n"+"".center(width,"="))
    print("\033[1m"+"STELLAPY BASH COMMANDS".center(width," ")+"\033[0m")
    print("".center(width,"="), "\n") 
    print("  Overview of the stellapy commands which work like Bash commands. ")
    print("  Developed by Hanne Thienpondt. ")
    print("  01/09/2022")
    print()
    print()
    
    # GUI (Graphical User Interface) 
    print("\033[1m GUI (Graphical User Interface) \033[0m")
    print("\033[1m ----------------------------- \033[0m", "\n")
    print("    ", " >> stellaplotter")
    print("    ", " >> stellaplotter_linear")
    print("    ", " >> stellaplotter_nonlinear")
    print()
    
    # Memory management
    print("\033[1m MEMORY MANAGEMENT \033[0m")
    print("\033[1m ----------------- \033[0m", "\n")
    print("    ", " >> reduce_sizeNetcdf")  
    print("    ", " >> replace_netcdfFile")  
    print() 
    
    # Data processing
    print("\033[1m DATA PROCESSING \033[0m")
    print("\033[1m --------------- \033[0m", "\n")
    print("    ", " >> write_dataFiles") 
    print("          ", " >> write_dataFiles -s ini") 
    print("          ", " >> write_dataFiles -s pot3D -t 1") 
    print("          ", " >> write_dataFiles -s phases --skip 10")
    print() 
   
    # Plot linear simulations
    print("\033[1m PLOT LINEAR SIMULATIONS \033[0m")
    print("\033[1m ---------------------- \033[0m", "\n")
    print("   ", "\033[1m TIME EVOLUTION \033[0m")
    print("   ", "\033[1m -------------- \033[0m") 
    print("      ", " >> plot_dphiz_vs_time")  
    print("      ", " >> plot_gamma_vs_time")   
    print("      ", " >> plot_omega_vs_time")     
    print() 
    print("   ", "\033[1m SPECTRA \033[0m")
    print("   ", "\033[1m ------- \033[0m")
    print("      ", " >> plot_gamma_vs_ky")   
    print("      ", " >> plot_omega_vs_ky") 
    print("      ", " >> plot_gamma_vs_kx")   
    print("      ", " >> plot_omega_vs_kx")   
    print() 
    print("   ", "\033[1m COMPLEX ANALYSIS \033[0m")
    print("   ", "\033[1m ---------------- \033[0m")
    print("      ", " >> plot_gamma")   
    print("      ", " >> plot_spectra")  
    print("      ", " >> plot_spectrum")  
    print() 
    
    # Plot nonlinear simulations
    print("\033[1m PLOT NONLINEAR SIMULATIONS \033[0m")
    print("\033[1m -------------------------- \033[0m", "\n")
    print("   ", "\033[1m TIME EVOLUTION \033[0m")
    print("   ", "\033[1m -------------- \033[0m")  
    print("      ", " >> plot_flux_vs_time --qflux")  
    print("      ", " >> plot_qflux_vs_time")  
    print("      ", " >> plot_pflux_vs_time")     
    print("      ", " >> plot_vflux_vs_time")       
    print() 
    
    print()
    return

#===============================================================================
#                             RUN AS BASH COMMAND                              #
#===============================================================================
 
if __name__ == "__main__":
    bash = Bash(list_commands, __doc__)  
    args = bash.get_arguments()
    del args['folder']
    list_commands(**args)   
    
