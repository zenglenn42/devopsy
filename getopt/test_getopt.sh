#!/bin/bash

#--------------------------------------------------------------------
# This skeleton shell script illustrates how to leverage getopt,
# a bash shell builtin, to parse command line arguments into
# script variables.
#
# Usage: test_getopt.sh -a arg1 -b arg2
#        test_getopt.sh -h                      # Returns help screen
#
# If the script runs nominally, it will return an error code of 0,
# typical of unix style scripting.  Otherwise it returns 1, indicating
# that the usage statement was displayed.
#
# The caller may check the results of the script programmatically by
# examining the return code in the $? shell variable.
#
# Example:
#   % ./test_getopt.sh -a hello -b world
#   % echo $?
#   0
#
#   % ./test_getopt.sh -h
#   % echo $?
#   1
#--------------------------------------------------------------------
SCRIPT=${0/*\/} # Basename of this script.
argc=$#         # Count the number of command line tokens.

# Enumerate the possible error return codes from this script.
ERR_SHOW_HELP=1
SUCCESS=0

# Default option arguments.
opt_a="dflt_a_value"
opt_b="dflt_b_value"

# Parse command line arguments.
while getopts a:b:h arg_name
do
  case $arg_name in
    a) opt_a=$OPTARG ;;
    b) opt_b=$OPTARG ;;
    h|?) cat <<-END >&2

		NAME: $SCRIPT -- Parse the command line with getopt

		USAGE:
		      $SCRIPT [-a a_argval] [-b b_argval]
		      $SCRIPT -h

		          -a # Describe a arg here
		          -b # Describe b arg here
		          -h # Help screen

		EXAMPLE:
		      $SCRIPT -a hello -b world
		      $SCRIPT -a aloha
		      $SCRIPT -h

		END
      exit $ERR_SHOW_HELP;;
  esac
done
shift $(( $OPTIND - 1 ))

# Show usage if no arguments on command line.
if [[ $argc == "0" ]]; then
  $0 -h 
  exit $ERR_SHOW_HELP
fi

echo "Running $0 with these parsed argument values ..."
echo "-----------------------------------------------------------------"
echo "opt_a = $opt_a"
echo "opt_b = $opt_b"

#--------------------------------------------------------------------
# Put your scripty stuff here, consuming the $opt_x variables ...
#--------------------------------------------------------------------

echo "-----------------------------------------------------------------"
echo "Done"
exit $SUCCESS
