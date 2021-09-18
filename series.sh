#!/bin/bash
################################################################################
#                              Series: the program                             #
#                                                                              #
# A simple script to automate the visualisation of digital media series        #
#                                                                              #
# Change History                                                               #
# XX/XX/2017  Pau Juan-Garcia    Original code version 0.0.1 for Linux Mint    #
# 11/04/2020  Pau Juan-Garcia    Original code version 0.1.0 for Linux Mint    #
# 18/04/2020  Pau Juan-Garcia    Original code version 0.1.1 for Linux Mint    #
# 07/08/2021  Pau Juan-Garcia    Original code version 0.1.2 for Linux Mint    #
#                                                                              #
#                                                                              #
################################################################################
#  Copyright (C) 2017, 2021 Pau Juan-Garcia                                    #
#  Pambientoleg@gmail.com                                                      #
#                                                                              #
#  This program is free software; you can redistribute it and/or modify        #
#  it under the terms of the GNU General Public License as published by        #
#  the Free Software Foundation; either version 3 of the License, or           #
#  (at your option) any later version. Available at:                           #
#  https://www.gnu.org/licenses/gpl-3.0.html                                   #
#                                                                              #
#  This program is distributed in the hope that it will be useful,             #
#  but WITHOUT ANY WARRANTY; without even the implied warranty of              #
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the                #
#  GNU General Public License for more details.                                #
################################################################################

################################################################################
# Configuration                                                                #
################################################################################
SERIESFOLDER="/home/paupau/Videos/series/"

################################################################################
# Help                                                                         #
################################################################################
Help()
{
  # Display Help
  echo "Description of the script functions:"
  echo
  echo "Syntax: series [-s:f:e:r|p|l|L|i:|I:|a:|d|P|n:|N|u|D:|h]"
  echo "options:"
  echo "s     Series name."
  echo "f     Filetype."
  echo "e     Number new episodes."
  echo "r     Play on repeat."
  echo "p     Watch current episody."
  echo "l     List available episodes."
  echo "L     List all media folders."
  echo "i     Provide details about a specific series."
  echo "I     Provide online information about a specific series."
  echo "a     Option to add series by folder name"
  echo "d     Directory where the new series is"
  echo "P     Create a marker for a previous episode"
  echo "n     Watch next episode. (or move forward any given number)"
  echo "N     Watch next episode and delete previous."
  echo "u     Update episode folder by a certain number of episodes."
  echo "D     Delete all episodes of a specific series."
  echo "h     Print this Help."
  echo
}

################################################################################
# Instructions
################################################################################

# To adjust file permissions: chmod +x series.sh
# To add scripts folder to PATH: PATH=$PATH:/Path/To/Script/Folder
# To use as a function in .bashrc:
# series () {
#   bash /home/paupau/Scripts/series.sh "$@"
# }
# Or, alternatively, if the function is defined in another file:
# source /home/paupau/Scripts/functions.sh
# To use the repeat mode it is necessary to adjust permissions

################################################################################
# Main program                                                                 #
################################################################################

# Functions
close_open_vlc () {
  # Delete any current VLC sessions
  session=$(pgrep vlc)
  if [[ ! -z "$session" ]]; then
    pgrep vlc | xargs -n1 kill -9
  fi
}

# Check there is at least one argument
if [ $# -eq 0 ]; then
  echo "No arguments provided"
  Help
  exit 1
fi

# Process the input options with getops (remember to use colons to indicate input arguments)
while getopts ":s:f:e:a:d:n:pPrlLi:I:NuD:h" option; do
  case $option in
    s) # Get series name
      SERIESNAME="$OPTARG" ;;
    f) # Get filetype if any
      FILETYPE=$OPTARG ;;
    e) # Get number of new episodes if any
      NUMBER=$OPTARG ;;
    a) # Option to add new series
      SERIESNAME="$OPTARG"
      ACTION="a" ;;
    d) # Directory with new series
      DIRECTORY="$OPTARG" ;;
    n) # Watch next episode (or move forward any given number)
      ACTION="n"
      if [[ ! -z $OPTARG ]]; then
        NUMBER=$OPTARG
      fi
      ;;
    p) # Watch current episody
      ACTION="p" ;;
    P) # Create marker for previous episode
      ACTION="P" ;;
    r) # Get series name to play on repeat
      REPEAT=true ;;
    l) # List available episodes
      ACTION="l" ;;
    L) # List all media folders
      ACTION="L" ;;
    i) # Provide details about a specific series
      SERIESNAME="$OPTARG"
      ACTION="i" ;;
    I) # Provide online information about a specific series
      SERIESNAME="$OPTARG"
      ACTION="I" ;;
    N) # Watch next episode and delete previous
      ACTION="N" ;;
    u) # Update episode folder by a certain number of episodes
      ACTION="u" ;;
    D) # Delete all episodes of a specific series
      SERIESNAME="$OPTARG"
      ACTION="D" ;;
    h) # Display Help
      Help
      exit ;;
    \?) # incorrect option
      echo "Error: Invalid option"
      exit ;;
esac
done

# Discard remaining arguments if any
shift $(( $OPTIND - 1 ))

# Set defaults
ACTION=${ACTION:-'n'}
NUMBER=${NUMBER:-1}

# Change to series folder
cd $SERIESFOLDER

# Check the folder exists and exit with error message otherwise
if [[ ! -z "$SERIESNAME" ]] && [[ $ACTION != "a" ]]; then
  if [[ ! -d "$SERIESNAME" ]]; then
    # TODO This does not seem to be working
    echo "Specified series $SERIESNAME does not exist"
    exit 1
  fi
fi

## Process all options
# Option to list all Video folder
if [[ $ACTION = L ]]; then
  cd ..
  # List all but text files
  ls --color=always *[^.txt] | less -r

# Option to provide list of episodes available
elif [[ $ACTION = l ]]; then
  ls --color=always */*[^.txt] | tr '\n' '\0' | xargs -0 -n 1 basename | less -r

# Option to checkout specific series
elif [[ $ACTION = i ]]; then
  cd "$SERIESNAME"
  # Get txt filename
  TXT_FILE=$(ls *.txt)
  # Read .txt file
  cat < $TXT_FILE | nl -v 0
  # Get count of remaining episodes (minus current)
  REMAINING=$(cat $TXT_FILE | wc -l)
  REMAINING=$(( $REMAINING - 1 ))
  echo "There are $REMAINING episodes remaining"

# Option to checkout specific series online
elif [[ $ACTION = I ]]; then
  bash ~/Scripts/movies.sh "$SERIESNAME"
  firefox --new-tab --search "$SERIESNAME" &

# Option for previous episode (default)
elif [[ $ACTION = p ]]; then
  cd "$SERIESNAME"
  # Select previous episode
  EPISODE=$(head -1 "${SERIESNAME}.txt")
  # Start vlc player and notify the user
  vlc -f "$EPISODE" &
  notify-send "Currently playing:" "$EPISODE"

# Option for previous episode (default)
elif [[ $ACTION = P ]]; then
  cd "$SERIESNAME"
  # Select previous episode
  sed -i "1i --- Line placeholder ---" "${SERIESNAME}.txt"
  echo "Created placeholder for previous episode in $SERIESNAME"

# Option for next episode and update list
elif [[ $ACTION = n ]] || [[ $ACTION = N ]]; then
  cd "$SERIESNAME"
  # Get next episode
  EPISODE=$(head -$(($NUMBER + 1)) "${SERIESNAME}.txt" | tail -1)
  PREV_EPISODE=$(head -1 "${SERIESNAME}.txt")
  # Delete previous epidode if desired
  if [[ $ACTION = N ]]; then
    rm $PREV_EPISODE
  fi
  # Delete previous episode from list
  tail -n +$(($NUMBER + 1)) "${SERIESNAME}.txt" > "${SERIESNAME}.tmp" && mv "${SERIESNAME}.tmp" "${SERIESNAME}.txt"
  # Delete any current VLC sessions
  close_open_vlc
  # Start vlc player
  vlc -f "$EPISODE" &
  notify-send "Currently playing:" "$EPISODE"

  # Process repeat option
  if [[ ! -z "$REPEAT" ]]; then
    DURATION=$(ffprobe -i $EPISODE -show_entries format=duration -v quiet | grep duration | sed 's/.*=//')
    sleep $(($DURATION + 3))
    # Launch script recursively
    "$0" -s $* "${SERIESNAME}" -r
  fi

# Option to add series by folder name (automatically create .txt)
elif [[ $ACTION = a ]]; then
  # Check filetype is set or use default
  if [[ -z "$FILETYPE" ]]; then
    FILETYPE="mkv"
    echo "File extension not provided. Assuming .mkv filetype"
  fi
  if [[ ! -z "$DIRECTORY" ]]; then
    # Create directory if does not exist yet
    if [[ ! -d "$SERIESNAME" ]]; then
      mkdir -p $SERIESNAME
    fi
    # Move all files to new directory
    mv "${DIRECTORY}"/*.${FILETYPE} ./"${SERIESNAME}"
  fi
  cd "$SERIESNAME"
  # Rename files to get rid of spaces if any
  find -type f | rename 's/ /_/g'
  # Create tracker file and report
  ls *.$FILETYPE > "${SERIESNAME}.txt"
  # Add initial line for first watch
  sed -i "1i --- Initial run ---" "${SERIESNAME}.txt"
  echo "Added $SERIESNAME to list of tracked series"
  # Launch script as info
  "$0" -i $* "${SERIESNAME}"

# Option to update new episodes
elif [[ $ACTION = u ]]; then
  cd "$SERIESNAME"
  ls *.$FILETYPE | tail -$NUMBER >> "${SERIESNAME}.txt"

# Option to delete all episodes in a folder
elif [[ $ACTION = D ]]; then
  cd "$SERIESNAME"
  rm -I *[^.txt]

fi
# IDEAS:
# Try to build autocomplete capabilities with list of series
## https://www.tldp.org/LDP/abs/html/tabexpansion.html
# Add a clean (-c) option, that updates and removes already seen episodes
# Use long options with: https://stackoverflow.com/questions/12022592/how-can-i-use-long-options-with-the-bash-getopts-builtin/30026641
