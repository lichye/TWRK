#!/bin/bash
if [ $1 == "sim" ];
then
	if [ -z "$3" ];
	then
		make MODULE_SIMFILES=verilog/$2.sv MODULE_TESTBENCH=testbench/$2_testbench.sv test
	else
		if [ $3 == "dve" ];
		then
			make MODULE_SIMFILES=verilog/$2.sv MODULE_TESTBENCH=testbench/$2_testbench.sv module_dve
		fi
	fi
elif [ $1 == "syn" ];
then
	if [ -z "$3" ];
	then
		make MODULE_SIMFILES=verilog/$2.sv MODULE_TCL=synth/$2.tcl MODULE_TESTBENCH=testbench/$2_testbench.sv MODULE_SYN=$2.vg module_syn
	else
		if [ $3 == "dve" ];
		then
			make MODULE_SIMFILES=verilog/$2.sv MODULE_TCL=synth/$2.tcl MODULE_TESTBENCH=testbench/$2_testbench.sv MODULE_SYN=$2.vg module_dve_syn
		fi
	fi
elif [ $1 == "pipeline" ];
then
	if [ "$2" == all ];
	then
        for file in test_progs/*.s; do
			file=$(echo $file | cut -d '/' -f2 | cut -d'.' -f1)
			echo $file
			cp test_progs/$file.s ../ground_truth/$file.s
			cd ../ground_truth
			make assembly SOURCE=$file.s
			make
			cp writeback.out ../master/in_order.out

			cd ../master
            make assembly SOURCE=test_progs/$file.s
            make sim
			if [ -z $(diff writeback.out ../ground_truth/writeback.out) ]
				then
					echo "Passed!"
				else
					echo $file fail
					diff writeback.out ../ground_truth/writeback.out > diff.out
					exit
			fi
			if [ -z "$(diff <(grep @@@ sim_program.out) <(grep @@@ ../ground_truth/program.out))" ]
            then
                echo -e "$GREEN@@@Program.out test passed!$NC"
            else
                echo -e "$RED@@@Program.out test failed!$NC"
				echo $file fail
				exit
            fi

            echo -e "$PURPLE--------------------Finish testing $file; Proceed to next one-------------------------$NC"
        done

        for file in test_progs/*.c; do
			file=$(echo $file | cut -d '/' -f2 | cut -d'.' -f1)
			echo $file
			cp test_progs/$file.c ../ground_truth/$file.c
			cd ../ground_truth
			make program SOURCE=$file.c
			make
			cp writeback.out ../master/in_order.out

			cd ../master
            make program SOURCE=test_progs/$file.c
            make sim
			if [ -z "$(diff writeback.out ../ground_truth/writeback.out)" ]
				then
					echo "Passed!"
				else
					echo $file fail
					diff writeback.out ../ground_truth/writeback.out > diff.out
					exit
			fi
			if [ -z "$(diff <(grep @@@ sim_program.out) <(grep @@@ ../ground_truth/program.out))" ]
            then
                echo -e "$GREEN@@@Program.out test passed!$NC"
            else
                echo -e "$RED@@@Program.out test failed!$NC"
				echo $file fail
				exit
            fi			

            echo -e "$PURPLE--------------------Finish testing $file; Proceed to next one-------------------------$NC"
        done
	elif [ "$2" == syn ];
	then
        for file in test_progs/*.s; do
			file=$(echo $file | cut -d '/' -f2 | cut -d'.' -f1)
			echo $file
			cp test_progs/$file.s ../ground_truth/$file.s
			cd ../ground_truth
			make assembly SOURCE=$file.s
			make
			cp writeback.out ../master/in_order.out

			cd ../master
            make assembly SOURCE=test_progs/$file.s
            make syn
			if [ -z $(diff writeback.out ../ground_truth/writeback.out) ]
				then
					echo "Passed!"
				else
					echo $file fail
					exit
			fi
			if [ -z "$(diff <(grep @@@ syn_program.out) <(grep @@@ ../ground_truth/program.out))" ]
            then
                echo -e "$GREEN@@@Program.out test passed!$NC"
            else
                echo -e "$RED@@@Program.out test failed!$NC"
				echo $file fail
				exit
            fi

            echo -e "$PURPLE--------------------Finish testing $file; Proceed to next one-------------------------$NC"
        done
        for file in test_progs/*.c; do
			file=$(echo $file | cut -d '/' -f2 | cut -d'.' -f1)
			echo $file
			cp test_progs/$file.c ../ground_truth/$file.c
			cd ../ground_truth
			make program SOURCE=$file.c
			make
			cp writeback.out ../master/in_order.out

			cd ../master
            make program SOURCE=test_progs/$file.c
            make syn
			if [ -z $(diff writeback.out ../ground_truth/writeback.out) ]
				then
					echo "Passed!"
				else
					echo $file fail
					exit
			fi
			if [ -z "$(diff <(grep @@@ syn_program.out) <(grep @@@ ../ground_truth/program.out))" ]
            then
                echo -e "$GREEN@@@Program.out test passed!$NC"
            else
                echo -e "$RED@@@Program.out test failed!$NC"
				echo $file fail
				exit
            fi			

            echo -e "$PURPLE--------------------Finish testing $file; Proceed to next one-------------------------$NC"
        done	
	else
		if [ "$3" == "s" ];
		then
				cp test_progs/$2 ../ground_truth/$2
				cd ../ground_truth
				make assembly SOURCE=$2
				make
				cp writeback.out ../master/in_order.out
				cd ../master
				make assembly SOURCE=test_progs/$2
				make sim
				if [ -z "$(diff writeback.out ../ground_truth/writeback.out)" ]
				then
					echo "Passed!"
				else
					diff writeback.out ../ground_truth/writeback.out > diff.out
					diff writeback.out ../ground_truth/writeback.out
				fi

				if [ -z "$(diff <(grep @@@ sim_program.out) <(grep @@@ ../ground_truth/program.out))" ]
				then
					echo -e "$GREEN@@@Program.out test passed!$NC"
				else
					echo -e "$RED@@@Program.out test failed!$NC"
					diff <(grep @@@ sim_program.out) <(grep @@@ ../ground_truth/program.out)
				fi					
		else
			if [ "$3" == "c" ];
			then
				cp test_progs/$2 ../ground_truth/$2
				cd ../ground_truth
				make program SOURCE=$2
				make
				cp writeback.out ../master/in_order.out
				cd ../master
				make program SOURCE=test_progs/$2
				make sim
				if [ -z "$(diff writeback.out ../ground_truth/writeback.out)" ]
				then
					echo "Passed!"
				else
					diff writeback.out ../ground_truth/writeback.out > diff.out
					diff writeback.out ../ground_truth/writeback.out
				fi

				if [ -z "$(diff <(grep @@@ sim_program.out) <(grep @@@ ../ground_truth/program.out))" ]
				then
					echo -e "$GREEN@@@Program.out test passed!$NC"
				else
					echo -e "$RED@@@Program.out test failed!$NC"
					diff <(grep @@@ sim_program.out) <(grep @@@ ../ground_truth/program.out)
				fi				
			fi
		fi			
	fi
fi

