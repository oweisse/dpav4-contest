Author: Ofir Weisse, www.ofirweisse.com, OfirWeisse@gmail.com

This attack is thoroughly described in a paper presented in CHES 2014, written with Yossef Oren & Avishai Wool: "A New Framework for Constraint-Based Probabilistic Template Side Channel Attacks".

Some code snippets were authored by Stefan Mangard, Mario Kirschbaum and Yossef Oren.

This is the Matlab sources as submitted to the DPA v4 contest. It was tested on Matlab 2012b with Neural Networks toolbox available.

To run the attack you should:
1. Edit LaunchRSMAttack_<windows|linux>. Edit the variables fifo_in_filename, fifo_out_filename to be the correct paths to the pipes. The path can be anything arbitrary that you have permissions to write to.

2. Run the attack wrapper provided by the DPA v4 contest available at
 http://www.dpacontest.org/v4/tools.php
 
3. run LaunchRSMAttack_linux.m or LaunchRSMAttack_windows.m, depending on your operating system

4. In case the attack did not finish properly for some reason, you may need to kill the attack wrapper, and possibly need to remove the pipe files (as selected by fifo_in_filename, fifo_out_filename).


--------------------------------------------------------
------------- Running an Example on Windows ------------
--------------------------------------------------------

1. execute in a shell: 
attack_wrapper.exe -t -d DPA_contestv4_rsm -x test_good_bad_good.txt -e v4_RSM -k 0 -f fifo

* DPA_contestv4_rsm is the data-base from the DPA v4 rsm contest
* test_good_bad_good.txt - a custom index file, you can find it along side the Matlab file

2. Open Matlab and browse to the file "LaunchRSMAttack_windows.m". Put a breakpoint right after "solver.Solve();". That's line 77 (breakpoint in line 78). Press F5 to run until the breakpoint.
Alternatively, you could do "load( 'solver.mat' )" to load an instance of the solver after running I prepared. "solver.mat" resides along side with the Matlab code.

In this point the attack wrapper will start sending the first trace to the Matlab code.

3. Execute the following Matlab code:
"""
%load( 'solver.mat' ) % to skip steps 1 and 2 above
column1 = solver.mixColsCostStoreNodes{1,1};
column2 = solver.mixColsCostStoreNodes{1,2};
column3 = solver.mixColsCostStoreNodes{1,3};
column4 = solver.mixColsCostStoreNodes{1,4};

plainIDs     = 1:4;
keyIDs       = 5:8;
addKeyIDs    = 9:12;
subBytesIDs  = 13:16;
shiftRowsIDs = 17:20;
x2_IDs = 21:24;
xt_IDs = 25:28;
x4_ID   = 29;
MC_IDS = 30:33;

%You can get the MC possible values of column 1 by:
mc1_vals = column1.values( :, MC_IDS);
mc2_vals = column2.values( :, MC_IDS);
mc3_vals = column3.values( :, MC_IDS);
mc4_vals = column4.values( :, MC_IDS);

candidateKeyQuartet1 =  column1.values( :, keyIDs );
candidateKeyQuartet2 =  column2.values( :, keyIDs );
candidateKeyQuartet3 =  column3.values( :, keyIDs );
candidateKeyQuartet4 =  column4.values( :, keyIDs );

%get key quartets probabilities
candidateKeysProbabilities1 = column1.valuesPrices; % sum( candidateKeysProbabilities1 ) == 1
candidateKeysProbabilities2 = column2.valuesPrices; % same
candidateKeysProbabilities3 = column3.valuesPrices; % same
candidateKeysProbabilities4 = column4.valuesPrices; % same


"""

4. finding the correct key candidate

Run the following Matlab code:
"""
%finding the correct key candidate
shiftRowsMapping = [ 1  6  11 16 ...
					5  10 15 4  ...
					9  14 3  8  ...
				   13 2  7  12 ];

AES_KEY = sscanf ( '6cecc67f287d083deb8766f0738b36cf164ed9b246951090869d08285d2e193b', ...                '%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x%2x'...
            ); %from the DPA contest data base. The key is the same for all traces.
			
column1CorrectCandidateIdx = find( ismember( candidateKeyQuartet1, ...
											 AES_KEY( shiftRowsMapping( 1:4 ) )', ...
											 'rows' ) );			
column2CorrectCandidateIdx = find( ismember( candidateKeyQuartet2, ...
											 AES_KEY( shiftRowsMapping( 5:8 ) )', ...
											 'rows' ) );		
column3CorrectCandidateIdx = find( ismember( candidateKeyQuartet3, ...
											 AES_KEY( shiftRowsMapping( 9:12 ) )', ...
											 'rows' ) );		
column4CorrectCandidateIdx = find( ismember( candidateKeyQuartet4, ...
											 AES_KEY( shiftRowsMapping( 13:16 ) )', ...
											 'rows' ) );		

column1CorrectCandidateProbability = candidateKeysProbabilities1( column1CorrectCandidateIdx );
column2CorrectCandidateProbability = candidateKeysProbabilities2( column2CorrectCandidateIdx );
column3CorrectCandidateProbability = candidateKeysProbabilities3( column3CorrectCandidateIdx );
column4CorrectCandidateProbability = candidateKeysProbabilities4( column4CorrectCandidateIdx );
"""

Comments:
- the file classifiers-2013_11_12_16-10-35.mat contain decoders for the RSM AES implementation in DPA v4. The techniques used to train the classifiers were published in "Practical Template-Algebraic Side Channel Attacks with Extremely Low Data Complexity" at HASP 2013, written with Yossef Oren and Avishai Wool. Additional information is available in my M.Sc thesis, soon to be published.

- To grasp a visual understanding of AES I absolutely recommend viewing the superb AES flash in
http://www.formaestudio.com/rijndaelinspector/archivos/Rijndael_Animation_v4_eng.swf 


Have Fun!
