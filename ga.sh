#!/bin/bash

#for comfort
#rm -rf .git


LOG_MESSAGE=("${GREEN}$(date +"%D %T" ):${NC} ga started")
LOG_ID=0
FILES_ARRAY=()
LINE_MESS=()

NC='\033[0m'
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[1;36m'
DONE="${GREEN}

================================
 ______   ____ __  _________
 |  __ \ / __ \| \ | |  ____|
 | |  | | |  | |  \| | |__
 | |  | | |  | | .   |  __|
 | |__| | |__| | |\  | |____
 |_____/ \____/|_| \_|______|

================================
${NC}
"


echo -e "${GREEN}WELCOME TO:'
  ______ _____ _______      _______ _______ _______ _____ _______ _______ _______ __   _ _______
 |  ____   |      |         |_____| |______ |______   |   |______    |    |_____| | \  |    |
 |_____| __|__    |         |     | ______| ______| __|__ ______|    |    |     | |  \_|    |

"
echo -e "${NC}"
read -p  "Press any key to continue> "
function make_dir_arr {
    local ind=0
    for ent in ${FILES_ARRAY[@]}; do
        if [ -d $ent ]; then
            ${FILESS_ARRAY_DIRS[ind]}=$ent
            ((ind++))
        fi
    done
}

function print_optmessage() {
    clear
    for (( i=LOG_ID; i>=0; i-- )); do
         echo -e "${LOG_MESSAGE[$i]}"
         echo
    done
    read -p "Hit enter to come back!"
    git_operations
}
function log_message_form {
    ((LOG_ID++))
    LOG_MESSAGE[$LOG_ID]="${GREEN}$(date +"%D %T" ):${NC} $1"
}
function select_option {

    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    cursor_blink_on()  { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to()        { printf "$ESC[$1;${2:-1}H"; }
    print_option()     { printf "   $1 "; }
    print_selected()   { printf "  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row()   { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
    key_input()        { read -s -n3 key 2>/dev/null >&2
                         if [[ $key = $ESC[A ]]; then echo up;    fi
                         if [[ $key = $ESC[B ]]; then echo down;  fi
                         if [[ $key = ""     ]]; then echo enter; fi; }

    # initially print empty new lines (scroll down if at bottom of screen)
    for opt; do printf "\n"; done

    # determine current screen position for overwriting the options
    local lastrow=`get_cursor_row`
    local startrow=$(($lastrow - $#))

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    local selected=0
    while true; do
        # print options by overwriting the last lines
        local idx=0
        for opt; do
            cursor_to $(($startrow + $idx))
            if [ $idx -eq $selected ]; then
                print_selected "$opt"
            else
                print_option "$opt"
            fi
            ((idx++))
        done
        echo
        echo
        echo
        echo
        echo
        echo -e "${LOG_MESSAGE[$LOG_ID]}"
        # user key control
        case `key_input` in
            enter) break;;
            up)    ((selected--));
                   if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi;;
            down)  ((selected++));
                   if [ $selected -ge $# ]; then selected=0; fi;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    return $selected
}

function multiselect {
    echo "[SPACE] - to select [ENTER - to continue]"
    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    cursor_blink_on()   { printf "$ESC[?25h"; }
    cursor_blink_off()  { printf "$ESC[?25l"; }
    cursor_to()         { printf "$ESC[$1;${2:-1}H"; }
    print_inactive()    { printf "$2   $1 "; }
    print_active()      { printf "$2  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row()    { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }

    local return_value=$1
    local -n options=$2
    local -n defaults=$3

    local selected=()
    for ((i=0; i<${#options[@]}; i++)); do
        if [[ ${defaults[i]} = "true" ]]; then
            selected+=("true")
        else
            selected+=("false")
        fi
        printf "\n"
    done

    # determine current screen position for overwriting the options
    local lastrow=`get_cursor_row`
    local startrow=$(($lastrow - ${#options[@]}))

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    key_input() {
        local key
        IFS= read -rsn1 key 2>/dev/null >&2
        if [[ $key = ""      ]]; then echo enter; fi;
        if [[ $key = $'\x20' ]]; then echo space; fi;
        if [[ $key = "k" ]]; then echo up; fi;
        if [[ $key = "j" ]]; then echo down; fi;
        if [[ $key = $'\x1b' ]]; then
            read -rsn2 key
            if [[ $key = [A || $key = k ]]; then echo up;    fi;
            if [[ $key = [B || $key = j ]]; then echo down;  fi;
        fi
    }

    toggle_option() {
        local option=$1
        if [[ ${selected[option]} == true ]]; then
            selected[option]=false
        else
            selected[option]=true
        fi
    }

    print_options() {
        # print options by overwriting the last lines
        local idx=0
        for option in "${options[@]}"; do
            local prefix="[ ]"
            if [[ ${selected[idx]} == true ]]; then
              prefix="[${GREEN}+${NC}]"
            fi
            cursor_to $(($startrow + $idx))
            if [ $idx -eq $1 ]; then
                print_active "$option" "$prefix"
            else
                print_inactive "$option" "$prefix"
            fi
            ((idx++))
        done
    }

    local active=0
    while true; do
        print_options $active

        # user key control
        case `key_input` in
            space)  toggle_option $active;;
            enter)  print_options -1; break;;
            up)     ((active--));
                    if [ $active -lt 0 ]; then active=$((${#options[@]} - 1)); 
                        
                    
                    fi;;
            down)   ((active++));
                    if [ $active -ge ${#options[@]} ]; then active=0; 
                        
                    
                    fi;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    eval $return_value='("${selected[@]}")'
}
#========================================================================================

function start() {
    clear
    echo "Current dir: $(pwd)"
    echo

    if git status &> /dev/null; then
        GITSTATUS=0
        echo -e "${GREEN}Git status successful${NC}"
        read -p "Press any key to move forward> "
        git_operations

    else

        echo -e "${RED}Git status failed${NC}"
        echo "There're no existing git repo in this dir, what your actions will be?"
        echo
        echo
        echo
        echo
        gitinit

    fi

    echo "STATUS is $GITSTATUS"
}

function gitinit() {
    while true;
    do

        echo "Type <help> for the comand list!"
        read -p "> " command
        case $command in
            help)

                echo "
                <init>        - create git repo
                <clone>       - clone existing repo from GitHub/Lab>
                <exit>
                "
                ;;
            init)

                git init
                while true;
                do
                    echo "Write name for remote repo, and paste link, example: <origin git@github.com:...> "
                    read -p "> " remoname remolink
                    if [ -z "$remoname" ]; then
                        echo -e "${RED} ERROR! There is no remote repo name!${NC}"
                        continue
                    elif [ -z "$remolink" ]; then
                        echo -e "${RED} ERROR! There is no remote repo url!${NC}"
                        continue
                    else
                        if git remote add $remoname $remolink &> /dev/null; then
                            git pull
                            echo "Pulled origin"
                            echo -e "${DONE}"
                            read -p "Press any key to move forward> "
                            git_operations
                        else
                          echo -e "${RED}Something went wrong!${NC}"
                          break
                        fi

                        break
                    fi
                done

                ;;
            clone)

                read -p "Paste link of your remote repo: " remorepolink
                if git clone $remorepolink &> /dev/null; then
                     echo -e "${DONE}"
                     read -p "Press any key to move forward> "
                     git_operations
                else
                    echo -e "${RED}Remote repo link is empty!${NC}"
                    continue
                fi

                ;;
            exit)
                clear
                break;
                ;;
            *)
                echo -e "${RED}ERROR:${NC} No such command!"
                ;;

        esac
    done
}

function git_operations() {
    clear

    while true;
    do
        FILES_ARRAY=( $( ls *) )
        
        
        echo "Select one option using up/down keys and enter to confirm:"
        echo
        options=(
        "status                 show modified files in working directory, staged for your next commit"
        "add                    add a file as it looks now to your next commit (stage)"
        "commit                 commit your staged content as a new commit snapshot"
        "reset stage            unstage a file while retaining the changes in working directory"
        "diff                   diff between of what is changed but not staged"
        "staged diff            diff between of what is staged but not yet commi"
        "commits history"
        "branches list          list your branches. a * will appear next to the currently active branch"
        "create branch          create a new branch at the current commit"
        "change branch"
        "stash                  save modified and staged changes"
        "stash list             list stack-order of stashed file changes"
        "pop stash              write working from top of stash stack"
        "drop stash             discard the changes from top of stash stack"
        "push                   Update remote refs along with associated objects"
        "pull                   Fetch from and integrate with another repository or a local branch"
        "logs"
        "quit"
        )

        select_option "${options[@]}"
        choice=$?

        echo "Choosen index = $choice"
        echo "        value = ${options[$choice]}"
        case "$choice" in
            0)
                echo "status"
                
                ;;
            1)
                git_add
                
                ;;
            2)
                git_commit
                
                ;;
            3)
                echo "reset stage"
                
                ;;
            4)
                echo "diff"
                
                ;;
            5)
                echo "staged diff"
                
                ;;
            6)
                echo "commits history"

                ;;
            7)
                echo "branches list"
                
                ;;
            8)
                echo "create branch"
                
                ;;
            9)
                echo "change branch"

                ;;
            10)
                echo "stach"
                
                ;;
            11)
                echo "stash list"
                
                ;;
            12)
                echo "pop stash"
                
                ;;
            13)
                echo "drop stash"
                
                ;;
            14)
                git_push
                continue
                ;;
            15)
                continue
                ;;
            16)
                continue
                ;;
            17)
                print_optmessage
                continue
                ;;
            18)
                break
                ;;
        esac


    done

}



function git_add() {
    clear
    local git_add_options=(
    "Add all"
    "Add separately"
    "back"
    )

    select_option "${git_add_options[@]}"
    choice=$?
    case $choice in
        0)
            git add .
            log_message_form "Files added:\n${CYAN}${FILES_ARRAY[*]}${NC}"

            ;;
        1)
            clear
            local my_options=(${FILES_ARRAY[@]})
            local git_add_array=()
            multiselect result my_options

            local idx=0
            for option in "${my_options[@]}"; do
                if [ ${result[idx]} == "true" ]; then
                    git_add_array[idx]=$option
                fi
                ((idx++))
            done
            #sleep 1000
            git add "${git_add_array[@]}"
            log_message_form "Files added:\n${CYAN}${git_add_array[*]}${NC}"        
               ;;
        *)
            git_operations
            ;;
    esac
    clear
}
function git_commit() {
    clear
    read -p "Provide commit message: " commit_message
    #sleep 1000
    if [ -ne "$commit_message" ]; then
        log_message_form "${RED}Empty commit message! Try again${NC}"
    else
        log_message_form "$(git commit -m "$commit_message")"

    fi
    clear
}
function git_push() {
    clear
    local branch_options=(
        $( git branch -a )
    )
    select_option "${branch_options[@]}"
    choice=$?
    echo "$choise"
    log_message_form "$(git push -u $( git remote ) "${branch_options[$choice]}")"
    #sleep 1000
    clear
}
#===========================================================================================
start