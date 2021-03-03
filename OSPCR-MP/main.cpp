#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <windows.h>
#include <stdbool.h>
#include <string>
#include <fstream>
#include <vector>
#include <iostream>
#include <cstring>

#define KEEP_WORKING 0
#define NO_MORE_JOBS 1
#define READY_TO_WORK 2
#define WORKER_NOT_AVAILABLE -1
#define MANAGER_RANK 0
#define VERSION "1.0.6"

using namespace std;
int get_rank_from_ready_worker();
void send_job_to_worker(string& job, string& tempF, int worker_rank);
void signal_to_manager_that_ready();
void get_data(ifstream& FileHandle, vector<string>& Lines, vector<string>& IDs, int& nJobs);
string concatenate_command(int& iteration, string& arguments, string& interpreterDir, string& scriptName, string& tempFileName);
void create_jobs(int& nJobs, string& interpreterDir, string& scriptName, vector <string>& arguments, vector <string>& commandCall, vector <string>& tempFile);
void do_job(string command, string tempFName, int my_rank); 
bool receive_job_from_manager(int my_rank);
void terminate_worker(int worker_rank);



int main(int argc, char** argv) {
    /* init MPI environment */
    MPI_Init(&argc, &argv);

    /* Find out rank, size */
    int world_rank, world_size;
    MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);

    /* Check that we have at least one manager & one worker */
    if (world_size < 2) {
        fprintf(stderr, "World size must be greater than 1 for %s\n", argv[0]);
        MPI_Abort(MPI_COMM_WORLD, 1);
    }


    if (world_rank == MANAGER_RANK) { /* manager part */
        cout << "OSPCR-MP - Version " << VERSION << endl;
        cout << "Analyses will be run on " << world_size << " processors. 1 manager and " << world_size - 1 << " workers." << endl;
        string tclFileName;
        string dataFileName;
        string OpenSeesDir;
        if (argc >= 4) {
            if (argc > 4) { cout << "Received " << argc << " arguments. Ignored additional arguments." << endl; }
            OpenSeesDir = argv[1];
            tclFileName = argv[2];
            ifstream tclFileHandle(tclFileName.c_str());
            if (!tclFileHandle.good()) {
                string errMessage = "Error accessing tcl file \"" + tclFileName + "\"";
                perror(errMessage.c_str());
                system("PAUSE");
                MPI_Finalize();
                return -1;
            }
            else
                cout << "tcl file \"" << tclFileName << "\" exists." << endl;

            dataFileName = argv[3];
            ifstream dataFileHandle(dataFileName.c_str());
            if (!dataFileHandle.good()) {
                string errMessage = "Error accessing data file \"" + dataFileName + "\"";
                perror(errMessage.c_str());
                system("PAUSE");
                MPI_Finalize();
                return -1;
            }
            else 
                cout << "data file \"" << dataFileName << "\" exists." << endl;
        } 
        else {
            if (argc > 1) { cout << "Received " << argc << " arguments. Less than 4, so ignoring all arguments." << endl; }

            cout << "Please specify name of the OpenSees.exe being used if you changed its name. " << endl;
            cout << "This program expects the .exe to be either:" << endl;
            cout << "a) In the present working directory, or " << endl;
            cout << "b) Its location was already added to the sytem path." << endl;;
            cout << "Kindly note that this programme cannot check either for you and will terminate" << endl;
            cout << "after getting all the file information if no OpenSees.exe is found." << endl;
            if (getline(cin, OpenSeesDir)) {
                if (OpenSeesDir.empty())
                {
                    OpenSeesDir = "OpenSeesDEBUG3.2.1";
                    cout << "Default .exe name \"" << OpenSeesDir << "\" will be used." << endl;
                }
            }
            cout << endl << "Please specify tcl filename WITH extension. If nothing entered default \"run.tcl\" is used" << endl;
            if (getline(cin, tclFileName)) {
                if (tclFileName.empty())
                {
                    tclFileName = "run.tcl";
                    cout << "Default tcl file name \"" << tclFileName << "\" will be used." << endl;
                }
            }
            ifstream tclFileHandle(tclFileName.c_str());
            if (!tclFileHandle.good()) {
                string errMessage = "Error accessing tcl file \"" + tclFileName + "\"";
                perror(errMessage.c_str());
                system("PAUSE");
                MPI_Finalize();
                return -1;
            }
            else
                cout << "tcl file \"" << tclFileName << "\" exists." << endl;

            cout << endl << "Please specify data filename WITH extension. If nothing entered default \"data.dat\" is used" << endl;
            if (getline(cin, dataFileName)) {
                if (dataFileName.empty())
                {
                    dataFileName = "data.dat";
                    cout << "Default data file name \"" << dataFileName << "\" will be used." << endl;
                }
            }

            ifstream dataFileHandle(dataFileName.c_str());
            if (!dataFileHandle.good()) {
                string errMessage = "Error accessing data file \"" + dataFileName + "\"";
                perror(errMessage.c_str());
                system("PAUSE");
                MPI_Finalize();
                return -1;
            }
            else {
                cout << "data file \"" << dataFileName << "\" exists." << endl;
                cout << "First line of data file will always be ignored, so be careful." << endl;
            }
        }
        /* create 'jobs'*/
        
        vector <string> arguments;
        vector <string> IDs;
        int nJobs = 0;
        ifstream dataFileHandle(dataFileName.c_str());
        get_data(dataFileHandle, arguments, IDs, nJobs);
        vector <string> commandCalls;
        vector <string> tempFileNames;
        create_jobs(nJobs, OpenSeesDir, tclFileName, arguments, commandCalls, tempFileNames);

        /* sending 'jobs'*/
        int job_to_send = 0, worker_rank;
        do { /* manager main loop: sending jobs to ready workers */
            worker_rank = get_rank_from_ready_worker();
            if (worker_rank != WORKER_NOT_AVAILABLE) {
                cout << "sending job " << job_to_send << " with ID " << IDs[job_to_send] << " to worker " << worker_rank << endl;
                send_job_to_worker(commandCalls[job_to_send], tempFileNames[job_to_send], worker_rank);
                job_to_send++;
            }
        } while (job_to_send < nJobs);

        /* All jobs done -> terminating workers */
        for (int nb_terminated = 0; nb_terminated < world_size - 1; nb_terminated++) {
            terminate_worker(get_rank_from_ready_worker());
        }
        string ReportName = "Report.txt";
        ofstream myReportHandle(ReportName, ios::ate);
        if (myReportHandle.is_open()) {
            cout << "report file created." << endl;
        }
        for (int i = 0; i < IDs.size(); i++) {
            ifstream logFileHandle("log\\log" + IDs[i] + ".log", ios::out | ios::binary);
            logFileHandle.seekg(-9,ios::end);
            if (logFileHandle.is_open()) {
                string finalLine;
                if (getline(logFileHandle, finalLine)) {
                    finalLine.pop_back();
                    if (!finalLine.compare("Success")) {
                        myReportHandle << IDs[i] + "\tOK\n";
                    }
                    else if (!finalLine.compare("Failure")) {
                        myReportHandle << IDs[i] + "\tNot OK\tPremature divergence. Check log file.\n";
                    }
                    else {
                        myReportHandle << IDs[i] + "\tNot OK\tother errors; analysis not started.\n";
                    }
                } 
            }
            logFileHandle.close();
        }
        myReportHandle.close();
        cout << "All jobs completed." << endl;
        system("PAUSE");

    }
    else { /* worker part */
     /* signal to manager that it's ready to work */
        signal_to_manager_that_ready();

        /* start working loop */
        bool keep_working;
        do {
            keep_working = receive_job_from_manager(world_rank);
        } while (keep_working);
    }

    MPI_Barrier(MPI_COMM_WORLD);   
    MPI_Finalize();
    return 0;
}

int get_rank_from_ready_worker() {
    MPI_Status status;
    int worker_useless_msg;
    MPI_Recv(&worker_useless_msg,
        1,
        MPI_INT,
        MPI_ANY_SOURCE,
        MPI_ANY_TAG,
        MPI_COMM_WORLD,
        &status);

    if (status.MPI_TAG == READY_TO_WORK) {
        return status.MPI_SOURCE;
    }
    else {
        return WORKER_NOT_AVAILABLE;
    }
}


void send_job_to_worker(string& job, string& tempF, int worker_rank) {
    MPI_Send(job.c_str(),
        job.size() + 1,
        MPI_CHAR,
        worker_rank,
        KEEP_WORKING,
        MPI_COMM_WORLD);
    MPI_Send(tempF.c_str(),
        tempF.size() + 1,
        MPI_CHAR,
        worker_rank,
        KEEP_WORKING,
        MPI_COMM_WORLD);
}


void signal_to_manager_that_ready() {
    int empty_msg = 0;
    MPI_Send(&empty_msg,
        1,
        MPI_INT,
        MANAGER_RANK,
        READY_TO_WORK,
        MPI_COMM_WORLD);
}

void get_data(ifstream& FileHandle, vector<string>& Lines, vector<string>& IDs, int& nJobs) {
    string line;
    while (getline(FileHandle, line))
    {
        nJobs++;
        Lines.push_back(line);
        string buffer;
        int i = 0;
        do {
            buffer.push_back(line[i]);
            i++;
        } while (!isspace(line[i]));
        IDs.push_back(buffer);
        buffer.clear(); // maybe unnecessary? still, keeps things safe and is rather cheap.
    }
    //Ignore the first line
    Lines.erase(Lines.begin());
    IDs.erase(IDs.begin());
    nJobs--;
    cout << "There are " << nJobs << " jobs to be performed." << endl;
}

string concatenate_command(int& iteration, string& arguments, string& interpreterDir, string& scriptName, string& tempFileName) {
    string path;
    string command;
    path = "start \"Job number " + to_string(iteration) + "\" " + interpreterDir;
    command = path + " " + scriptName + " " + arguments + " > " + tempFileName;
    return command;
}
void create_jobs(int& nJobs, string& interpreterDir, string& scriptName, vector <string> & arguments, vector <string> & commandCall, vector <string> & tempFile) {
    int jobIndex = 0;
    for (int job = 1; job <= nJobs; job++) {
        tempFile.push_back("temp" + to_string(job) + ".txt");
        jobIndex = job - 1;
        commandCall.push_back(concatenate_command(job, arguments[jobIndex], interpreterDir, scriptName, tempFile[jobIndex]));
    }
} 

bool receive_job_from_manager(int my_rank) {
    
    MPI_Status status;
    MPI_Probe(MANAGER_RANK, MPI_ANY_TAG, MPI_COMM_WORLD, &status);
    int command_size = 0;
    MPI_Get_count(&status, MPI_CHAR, &command_size);
    char *command = new char[command_size];
    MPI_Recv(command,
        command_size,
        MPI_CHAR,
        MANAGER_RANK,
        MPI_ANY_TAG,
        MPI_COMM_WORLD,
        &status);

    if (status.MPI_TAG == KEEP_WORKING) { /* received a job to perform */
    MPI_Probe(MANAGER_RANK, MPI_ANY_TAG, MPI_COMM_WORLD, &status);
    int tempFname_size = 0;
    MPI_Get_count(&status, MPI_CHAR, &tempFname_size);
    char* tempFName = new char[tempFname_size];
    MPI_Recv(tempFName,
        tempFname_size,
        MPI_CHAR,
        MANAGER_RANK,
        MPI_ANY_TAG,
        MPI_COMM_WORLD,
        &status);
        do_job(command, tempFName, my_rank);
        /* tell manager that it's ready to perform a new job */
        signal_to_manager_that_ready();
        delete[] command;
        delete[] tempFName;
        return true;

    }
    else if (status.MPI_TAG == NO_MORE_JOBS) { /* work is over ! */
        delete[] command;
        return false;
    }
    else { /* this should not happen */
        delete[] command;
        return false;
    }
    
}

void do_job(string command, string tempFName, int my_rank) {
    int outPut = system(command.c_str());
    ifstream ifs(tempFName);
    ifs.close();
    while (remove(tempFName.c_str()) != 0) {
         //this while loop presents a huge weak point since if, for any reason, 
         //the temporary file cannot be deleted then the loop will continue forever!
    }
    std::cout << "Worker " << my_rank << " completed the job." << endl;
}

void terminate_worker(int worker_rank) {
    string empty_job = "fin";
    MPI_Send(empty_job.c_str(),
        empty_job.size()+1,
        MPI_CHAR,
        worker_rank,
        NO_MORE_JOBS,
        MPI_COMM_WORLD);
}
