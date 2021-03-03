# OpenSees Parametric Case Runner - Multi Processing
OSPCR-MP leverages the inherent argv capabilities of the tcl language and the ability to launch .tcl scripts in OpenSees from the command prompt. Using this program you will be able to anlayse multiple parametric cases in OpenSees at the same time. Seeing how all my colleauges use Windows in the office, this program was designed for that platform exclusively. It will, unfortunately, not run on Unix systems. 

## News
### Version 1.0.5 released
- exe can now take command-line arguments. See RunAnalysis2.bat in release package. 
### Version 1.0.1 released
- Fixed bug with evaluation of analyses outcome - report.txt now correctly identifies successful and failed analyses. 

## Prerequisites
- Multi-threaded Windows computer.
- Installation of [Microsoft MPI][1].
- A working OpenSees executable.

## Setting up your parametric cases
To run your parametric cases with OSPCR-MP you will need two things:
1. A parametric .tcl script.
2. An ordered Tab-separated data file.

To assist you in preparing your parametric script I have included a template file "run.tcl" in the release download section (version 1.0.0). There are some particular items that you must always include in your script. 
- The first argument you pass to the script must always be a unique ID number to help the script identify its input files (if any) and name its log and output files.
- For best loging of your analysis, it is best to keep the log file command (with its ID-defined name) on top of your .tcl script as shown in the template.
- For best reporting on your final anlaysis, make sure to keep the final if-statement from the template in your file and as the last section in your script.

The template file for the data file "data.dat" shows how to organize the arguments that your .tcl script will take. As already mentioned, a unique ID number must be the first entry in each line. While the arguments do not have to be numbers, they must be separated by a single Tab (the button on your keyboard). This is automatically done for your if you copy your data from an excel spreadsheet into the .dat file, which is what you will most likely be doing. 

## Debugging your .tcl script
Since this likely is your first .tcl script that takes external arguments you may run into some trouble and need to debug your script. To do that , just take one line out of your data.dat file, create a .txt file in your directory and type in the following 2 lines:

[YourOpenSees] yourTclScript.tcl [Your single copied data.dat line]
PAUSE

Promptly replacing [YourOpenSees] with the name of your OpenSees executable (most likely just OpenSees), and yourTclScript.tcl with your .tcl script name. Do not forget to type in "PAUSE" on the next line to allow you to see the OpenSees output. Save the file, and rename its extension from .txt to .bat, then double click it to run a single instance of OpenSees with your script and the single data line you used.

## Running your first analysis
After you prepare your .tcl script and data file, there are a few things you need to note before you run your analysis:
- Your files must all be in the same folder including any input files for earthquake records or temperature files.
- The folder you put your files in must not be write-protected (e.g. not in C:\Program Files). 
- You must either include the path to OpenSees in your system environment variables, or include the executable in the folder in which you will be running your parametric study.
- You have to be sure that there is enough space for your generated results file to live in the directory you are running your analysis within. 

Now that you prepared the directory where you want to run your parametric analysis, it is time to execute it. Since this software is built using the MS-MPI library you will need to have a working installation of it on your computer. To check the installation of MS-MPI and that its environment variables have been set, you should run the command prompt in administrator mode and type "set MSMPI". You should see at least 2 lines one of which one would be pointing to "\\Microsoft MPI\Bin". 

The final step in running your parametric case is to either execute OSPCR-MP.exe from the command prompt (called to the directory in which you're working) using the command:
mpiexec -n NUMBER OSPCR-MP.exe
where you replace "NUMBER" by the number of processors you want to dedicate to the job. Otherwise, you can use the RunAnalysis.bat file I included in the release which basically contains the command above. 

If you have done everything correctly and you're lucky, you should get a command prompt window asking for some inputs from you. Follow the instructions on the screen, and  your analysis should be running on n-1 the number of processors you allocated to the job!




[1]: https://www.microsoft.com/en-us/download/details.aspx?id=100593
