
import os, pathlib   
from stellapy.utils.files.remove_simulationsWithoutOutncFile import remove_simulationsWithoutOutncFile

def get_filesInFolder(folders=None, name_inputFile=None, start=None, end=None, subfolder=False):
    ''' Returns all files inside <folder> that starts with <start> and end with <end>. 

    If <input_file> is given, look for corresponding output files.
    Return the file names if full_path = False, otherwise return the full path names.
    ''' 
    
    # Initiate the list
    files_inside = [] 
    
    # Make sure we have a list of folders
    if isinstance(folders, pathlib.PurePath):
        folders = [folders]
    
    # Go through the folders to find the required files
    for folder in folders: 
        
        # Files inside this folder
        files_inside_folder = []
    
        # If <name_inputFile> is given, look for the corresponding output file
        if name_inputFile and end:
            if not end.startswith('.'): end = '.' + end
            file_inside = folder / name_inputFile.split('.in')[0] + end
            if os.path.isfile(file_inside):
                return file_inside
    
        # Read the files in <folder> that start with <start> and end with <end> 
        for file_name in os.listdir(folder):
            
            if not file_name.startswith('.'):
                
                # If the <file_name> starts with <start> and ends with <end>, add it to files_inside.
                if end and start:
                    if file_name.endswith(end) and file_name.startswith(start):
                        files_inside_folder.append(folder / file_name)    
                elif end:
                    if file_name.endswith(end):
                        files_inside_folder.append(folder / file_name)  
                elif start: 
                    if file_name.startswith(start) : 
                        files_inside_folder.append(folder / file_name)  
                else:
                    files_inside_folder.append(folder / file_name)  
        
                # If <file_name> starts with "run" then this refers to a sub_folder containing a simulation.
                if file_name.startswith("run") and os.path.isdir(file_name):
                    for file_name_run in os.listdir(folder / file_name):
                        if not file_name_run.startswith("."):
                            # If the <file_name> starts with <start> and ends with <end>, add it to files_inside.
                            if end and start:
                                if file_name_run.endswith(end) and file_name_run.startswith(start):
                                    files_inside_folder.append(folder / file_name / file_name_run)    
                            elif end:
                                if file_name_run.endswith(end):
                                    files_inside_folder.append(folder / file_name / file_name_run)  
                            elif start:
                                if file_name_run.startswith(start) :
                                    files_inside_folder.append(folder / file_name / file_name_run) 
                                    
                # If their are more folders, look into these as well
                if os.path.isdir(folder / file_name):
                    files = get_filesInFolder(folder / file_name, name_inputFile, start, end, subfolder=True)
                    if files:
                        files_inside_folder += files

        # Add these files to the big list
        files_inside += files_inside_folder
    
    # If we asked for input files, remove the files without an output file  
    if end=="in" and not subfolder:  files_inside = remove_simulationsWithoutOutncFile(files_inside)  
    if end==".in" and not subfolder: files_inside = remove_simulationsWithoutOutncFile(files_inside)   
    
    # Don't return duplicates
    files_inside = list(set(files_inside))
    
    # If no files were identified, return None 
    if files_inside == []: return None
    else:                  return files_inside 
    





