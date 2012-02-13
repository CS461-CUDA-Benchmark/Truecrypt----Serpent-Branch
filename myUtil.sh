#!/bin/bash

#FUNCTION DEFINITIONS
#Displays the usage message and exits the program.
function displayUsage()
{
	echo "USAGE:"
	echo "myUtil -c filename"
	echo "displays all comments that start with //"
	echo " "
	echo "myUtil -f filename searchText"
	echo "searches filename for searchText and optionally replaces it"
	echo " "
	echo "myUtil -m filename1 filename2"
	echo "removes the ^M characters that some editors insert"
	echo " "
	echo "myUtil -s searchText"
	echo "searches every file in the directory for the search Text"
	echo "==========================="
	echo "Provide the filename of a regular or existing file"
	exit
}

#Checks that the user has provided the required number of arguments, or prints an error message and exits the program
# $1: The number of arguments the user provided
# $2: The number of arguments required
function checkArguments()
{
	if [ $1 -ne $2 ]
	then
		displayUsage
	fi
}

#Checks that the file is valid, otherwise prints an error message and exits the program.
# $1: The file to check the validity of
function checkFile()
{
	if [ -f $1 ]
	then
		x=1; #As I do not know the logical negation for .sh scripts, this is simply a do-nothing command when the file _is_ valid
	else
		echo "ERROR: File does not exist or is invalid"
		echo "Invalid file: $1"
		exit
	fi
}

#Implements the functionality for listing all the comments in the specified file
# $1: The specified file to get the comments of
function listComments()
{
	#Pipe 1: Get each line that has a // in it and add line numbers
	#Pipe 2: Remember the digits (\1) at the beginning of the line then replace everything before "//" with the remembered digits (\1) followed by a ":"
	grep -ne // $1 | sed -r 's/^([0-9]*)[^/]*\/\//\1: /g'
}

#Implements the 2nd functionality in which the user searches the file for a specific text, then optionally replaces that text.
# $1: The specified file to search
# $2: The specified text to search for
# @pre: $1 is a valid file
function findAndReplace()
{
	#Print the lines of the specified file containing the specified text
	grep -ne $2 $1
	#Ask the user which line number they wish to edit and store that result in $ans
	read -p "Which line number do you want to edit?" ans
	#Ask the user what text they would like to place the specified text ($2) with and store the despired replacement text in $replacementText
	read -p "What would you like to replace $2 with?" replacementText
	#If the user enters valid replacement text...
	if [ $replacementText ]
	then
		#Replace the specified text at the specified line with the replacement text.
		#Pipe 1: Get the lines from the specified file with the specified text
		#Pipe 2: Match the lines with the line numbers specified by the user
		#Pipe 3: Remove the line numbers from the output
		#Pipe 4: Replace and print the specified text at the specified line with the replacement text
		grep -ne $2 $1 | grep -e ^$ans: | sed -r "s/^[0-9]*://g" | sed -r "s/$2/$replacementText/g"
	#Otherwise, the user entered no replacement text...
	else
		#Display the current text at the line specified by the user
		#Pipe 1: Get the lines from the specified file with the specified text
		#Pipe 2: Get the lines beginning with the specified line number
		#Pipe 3: Delete the line number so only the line text is displayed
		grep -ne $2 $1 | grep -e ^$ans: | sed -r "s/^[0-9]*://g"
	fi
	
}
#Implements the 3rd functionality in which all the ^M in the original file are replaced and copied into a new file and possibly the original file, depending on user input.
# $1: The name of the original file
# $2: The name of the new file
function removeHatM()
{
	#Check to see if the new file already exists and is a valid file
	if [ -f $2 ]
	then
		#Check that the user wants to overwrite  the existing file
		read -p "Are you sure you wish to overwrite the file $2? Enter \"y\" to confirm." ans
		#If the user wishes to overwrite the file, call the removeHatM helper function, which actually removes all the ^M 's from the file
		if [ $ans == "y" ]
		then
			_removeHatM $1 $2
		#Otherwise, the script insults the user, exits the program, and tech support gets many angry calls.
		else
			echo "Way to wimp out and not replace $2. Jeeze."
			exit
		fi
	#Otherwise, if the file exists but is invalid, print an error message and exit the program
	elif [ -e $2 ]
	then
		echo "ERROR: The file exists but is not usable"
		exit
	#Otherwise, the file does not exist, and the removeHatM helper function is called, which actually removes all the ^M 's from the file
	else
		_removeHatM $1 $2
	fi
}
#Helper function for removeHatM. This function removes the ^M, and asks if the user would like to overwrite the original file with the new file.
# $1: The name of the original file
# $2: The name of the new file
function _removeHatM()
{
	#Removes all the ^M 's in the original file ($1) and copies the result into the new file ($2)
	sed -r "s///g" $1 > $2
	#Prints the new file to the screen
	cat $2
	#Asks if the user would like to rename the new file ($2) as the original file ($1)
	read -p "Would you like to rename $2 as $1? Enter \"y\" to confirm." ans
	#If the user specifies yes...
	if [ $ans == "y" ]
	then
		#Rename the new file ($2) as the original file ($1)
		mv $2 $1
		echo "File moved"
	#Otherwise...
	else
		#Do not move the file
		echo "You chose not to move $2 to $1"
	fi
}

#Recursively search the directory for the provided string, and print out the filename, line number, and whole line where matches are found
# $1: The string to search for
function findString()
{
	#This variable acts as a boolean that keeps track of whether or not any output has been printed to the screen
	output=0
	#For each file in the current directory...
	for file in *; do
		#If the file is a valid file...
		if [ -f $file ]
		then
			#Print out all the lines of the current file matching the specified text
			grep -Hne $1 $file
			#If the line count from a copy of the previous command was _not_ 0...
			if [ `grep -Hne $1 $file | wc -l` -ne 0 ]
			then
				#Set the output variable to confirm that output was printed to the screen
				output=1
			fi
		fi
	done
	#If no output was printed to the screen....
	if [ $output -eq 0 ]
	then
		#Inform the user that no occurences of their specified search text was found.
		echo "No occurences of $1 found"
	fi
}

#MAIN PROGRAM
#If the user has provided no arguments, display a usage message and exit.
if [ $# -eq 0 ]
then
	displayUsage
#Else if the first argument is a -c...
elif [ $1 == "-c" ]
then
	checkArguments $# 2	#Check that the user provided 2 arguments
	checkFile $2		#Check that the file is valid
	listComments $2		#List the comments of the file
#Else if the first argument is a -f...
elif [ $1 == "-f" ]
then
	checkArguments $# 3	#Check that the user provided 3 arguments
	checkFile $2		#Check that the file is valid
	findAndReplace $2 $3	#Call the findAndReplace function
#Else if the first argument is a -m...
elif [ $1 == "-m" ]
then
	checkArguments $# 3	#Check that the user has provided 3 arguments
	checkFile $2		#Check that file1 is valid
	removeHatM $2 $3	#Remove the ^M characters from the file
#Else if the first argument is a -s...
elif [ $1 == "-s" ]
then
	checkArguments $# 2	#Check that the user has provided 2 arguments
	findString $2		#Recursively search the current directory and print out all matches
#Otherwise, display a usage message and exit
else
	displayUsage
fi
