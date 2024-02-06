#!/bin/bash

#for comfort
#rm -rf .git


LOG_MESSAGE=("${GREEN}$(date +"%D %T" ):${NC} ga started")
LOG_ID=0
FILES_ARRAY=()
LINE_MESS=()
PRESENT_BRANCH=""
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
            #escape) git_operations;;
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
function present_branch() {
    PRESENT_BRANCH=$(git branch | awk '/\* /')
}
function git_operations() {
    clear
    present_branch
    echo 
    echo -e "${CYAN}--> Current branch:${GREEN} $PRESENT_BRANCH${NC}"
    echo 
    
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
        "commits history"
        "branches list          list your branches. a * will appear next to the currently active branch"
        "create branch          create a new branch at the current commit"
        "change branch"
        "delete branch"
        "merge                  merge the specified branch\’s history into the current one"
        "stash                  save modified and staged changes"
        "stash list             list stack-order of stashed file changes"
        "pop stash              write working from top of stash stack"
        "drop stash             discard the changes from top of stash stack"
        "add remote"
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
                git_status
                ;;
            1)
                git_add
                
                ;;
            2)
                git_commit
                
                ;;
            3)
                #echo "reset stage"
                git_reset_stage
                ;;
            4)
                #echo "commits history"
                git_log
                ;;
            5)
                #echo "branches list"
                git_branch
                ;;
            6)
                #echo "create branch"
                git_checkout_b
                ;;
            7)
                #echo "change branch"
                git_change_branch
                ;;
            8)
                #echo "git delete branch"
                git_delete_branch
                ;;
            9)
                #echo "git merge"
                git_merge
                ;;
            10)
                #echo "stach"
                git_stash
                ;;
            11)
                
                #echo "stash list"
                git_stash_list
                ;;
            12)
                
                #echo "pop stash"
                git_stash_pop
                ;;
            13)
                #echo "drop stash"
                git_stash_drop
                
                ;;
            14)
                git_remote_add
                
                ;;
            15)
                git_push
                
                ;;
            16)
                git_pull
                
                ;;
            17)
                print_optmessage
                
                ;;
            *)
                kill $$
                ;;
        esac


    done

}

function git_status() {
    clear
    git status
    echo
    echo
    read -p "Press any key to continue>"
    git_operations
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
            log_message_form "All files added!"

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
    if [[ $(git status) =~ "Changes to be committed:" ]]; then
        read -p "Provide commit message: " commit_message
        #sleep 1000
        if [ -ne "$commit_message" ]; then
            log_message_form "${RED}Empty commit message! Try again${NC}"
        else
            log_message_form "$(git commit -m "$commit_message")"

        fi
    else
        log_message_form "${RED}There is nothing to commit! Add files first!${NC}"
    fi
    clear
}
function git_reset_stage() {
    clear
    if [[ $(git status) =~ "Changes to be committed:" ]]; then
        local git_reset_options=(
        "Reset all"
        "Reset separately"
        "back"
        )
        
        select_option "${git_reset_options[@]}"
        choice=$?
        case $choice in
            0)
                git reset .
                log_message_form "All files are reseted!"

                ;;
            1)
                clear
                local staged_array=()
                while IFS="" read -r staged_file ; do
                    #if [[ staged_array~="error:" ]]; then
                    #    continue
                    #else
                        staged_array+=("$staged_file")
                    #fi
                done < <(git diff --name-only --cached)
                #echo ${staged_array[@]}
                #sleep 1000
                local my_options=(${staged_array[@]})
                local git_reset_array=()
                multiselect result my_options

                local idx=0
                for option in "${my_options[@]}"; do
                    if [ ${result[idx]} == "true" ]; then
                        git_reset_array[idx]=$option
                        
                    fi
                    ((idx++))
                done
                #echo ${git_reset_array[@]}
                #sleep 1000
                git reset "${git_reset_array[@]}"
                log_message_form "Files reseted:\n${CYAN}${git_reset_array[*]}${NC}"        
                ;;
            *)
                git_operations
                ;;
        esac
    else
        log_message_form "${RED}There is nothing to unstage!${NC}"
        git_operations
    fi
    clear
}
function git_log() {
    clear
    git log
    echo
    read -p "Press any key to continue>"
    git_operations
}
function git_branch() {
    clear
    git branch
    read -p "Press any key to continue>"
    git_operations

}
function git_checkout_b() {
    clear
  
        read -p "Provide branch name: " branch_name
        #sleep 1000
        if [ -ne "$branch_name" ]; then
            log_message_form "${RED}Empty branch name! Try again!${NC}"
        else
            git checkout -b $branch_name
            log_message_form "Succesfuly created branch: $branch_name"

        fi
    git_operations

}
function git_change_branch() {
     clear
   
        local git_branch_options=()
        while IFS=" " read -r branch ; do
                   
            git_branch_options+=("$branch")
                   
        done < <(git branch)
        select_option "${git_branch_options[@]}"
        choice=$?
        git checkout ${git_branch_options[$choice]}
        log_message_form "Succesfuly changed current branch to: ${git_branch_options[$choice]}"

    git_operations
}
function git_delete_branch() {
 clear
    echo "Select which branch you want to delete(current choosen branch wont be displayed)"
    local git_branch_options=()
    while IFS=" " read -r branch ; do
        if [[ $branch == $PRESENT_BRANCH ]]; then
            continue
            #echo $git_branch_options
        fi   
        git_branch_options+=("$branch")
                   
    done < <(git branch)
    
    select_option "${git_branch_options[@]}"
    choice=$?
    log_message_form "$(git branch -d ${git_branch_options[$choise]})"
    git_operations
}
function git_merge() {
    clear
    #echo "Select which branch you want to merge in $PRESENT_BRANCH"
    local git_branch_options=()
    while IFS=" " read -r branch ; do
        if [[ $branch == $PRESENT_BRANCH ]]; then
            continue
            #echo $git_branch_options
        fi   
        git_branch_options+=("$branch")
                   
    done < <(git branch)
    
    select_option "${git_branch_options[@]}"
    choice=$?
    #log_message_form "(${git_branch_options[$choice]})" 
    log_message_form "$( git merge ${git_branch_options[$choice]} )" 
    git_operations
}
function git_stash() {
    clear
    if [[ $(git status) =~ "Changes to be committed:" ]]; then
        log_message_form "$(git stash)"
        
    else
        log_message_form "${RED}There is nothing to stash! Add files first!${NC}"
    fi
    git_operations
}
function git_stash_list() {
    clear
    git stash list
    read -p "Press any key to continue>"
    git_operations
}
function git_stash_pop() {
    clear
    log_message_form "$(git stash pop)"
    git_operations
}
function git_stash_drop() {
    clear
    log_message_form "$(git stash drop)"
    git_operations
}
function git_remote_add() {
    while true;
    do
    clear
    
        echo "Write name for remote repo, and paste link, example: <origin git@github.com:...> "
        read -p "> " remoname remolink            
        if [ -z "$remoname" ]; then
            echo -e "${RED} ERROR! There is no remote repo name!${NC}"
            continue          
        elif [ -z "$remolink" ]; then
            echo -e "${RED} ERROR! There is no remote repo url!${NC}"
            continue      
        else    
            break
            log_message_form "$(git remote add $remoname $remolink)"
            git_operations
        fi       
    done
    git_operations
}
function git_push() {
    clear
        echo "Select remote:"
        local git_remote_options=()
        while IFS=" " read -r remote ; do
                   
            git_remote_options+=("$remote")
                   
        done < <(git remote)
        select_option "${git_remote_options[@]}"
        choice=$?
        #log_message_form "${git_remote_options[$choice]} ${PRESENT_BRANCH//\*}"
        log_message_form "$(git push -u ${git_remote_options[$choise]} ${PRESENT_BRANCH//\*})"

    git_operations
}
function git_pull() {
     clear
        echo "Select remote:"
        local git_remote_options=()
        while IFS=" " read -r remote ; do
                   
            git_remote_options+=("$remote")
                   
        done < <(git remote)
        select_option "${git_remote_options[@]}"
        choice=$?
        #log_message_form "${git_remote_options[$choice]} ${PRESENT_BRANCH//\*}"
        log_message_form "$(git pull ${git_remote_options[$choise]} ${PRESENT_BRANCH//\*})"

    git_operations
}
#===========================================================================================
start