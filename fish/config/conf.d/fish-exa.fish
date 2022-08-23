function __fish_exa_install --on-event fish-exa_install
    set -Ux __FISH_EXA_BASE_ALIASES l ll lg le lt lc lo
    set -Ux __FISH_EXA_EXPANDED a d i id aa ad ai aid aad aai aaid
    set -Ux __FISH_EXA_EXPANDED_OPT_NAME LA LD LI LID LAA LAD LAI LAID LAAD LAAI LAAID
    set -Ux __FISH_EXA_OPT_NAMES
    set -Ux __FISH_EXA_ALIASES
    set -Ux __FISH_EXA_SORT_OPTIONS name .name size ext mod old acc cr inode

    set -Ux EXA_STANDARD_OPTIONS "--group" "--header" "--group-directories-first"

    # Base aliases
    set -Ux EXA_L_OPTIONS
    set -Ux EXA_LL_OPTIONS "--long"
    set -Ux EXA_LG_OPTIONS "--git" "--git-ignore" "--long"
    set -Ux EXA_LE_OPTIONS "--extended" "--long"
    set -Ux EXA_LT_OPTIONS "--tree" "--level"
    set -Ux EXA_LC_OPTIONS "--across"
    set -Ux EXA_LO_OPTIONS "--oneline"

    # Extended aliases
    set -Ux EXA_LI_OPTIONS "--icons"
    set -Ux EXA_LD_OPTIONS "--only-dirs"
    set -Ux EXA_LID_OPTIONS "--icons"
    set -Ux EXA_LA_OPTIONS "--all" "--binary"
    set -Ux EXA_LAD_OPTIONS "--all" "--binary" "--only-dirs"
    set -Ux EXA_LAI_OPTIONS  "--all" "--binary" "--icons"
    set -Ux EXA_LAID_OPTIONS  "--all" "--binary" "--icons" "--only-dirs"
    set -Ux EXA_LAA_OPTIONS "--all" "--all" "--binary"
    set -Ux EXA_LAAD_OPTIONS "--all" "--all" "--binary" "--only-dirs"
    set -Ux EXA_LAAI_OPTIONS  "--all" "--all" "--binary" "--icons"
    set -Ux EXA_LAAID_OPTIONS  "--all" "--all" "--binary" "--icons" "--only-dirs"

    for a in $__FISH_EXA_BASE_ALIASES
        set -l opt_name (string join '_' "EXA" (string upper $a) "OPTIONS")
        if test $a = "ll"
            alias --save "$a" "exa_git"
        else
            alias --save "$a" "exa \$EXA_STANDARD_OPTIONS \$$opt_name"
        end
        set -a __FISH_EXA_OPT_NAMES "$opt_name"
        set -a __FISH_EXA_ALIASES "$a"

        for i in (seq (count $__FISH_EXA_EXPANDED))
            set -l name "$a$__FISH_EXA_EXPANDED[$i]"
            # --tree is useless given --all --all
            if test $name = "ltaa"; or test $name = "ltaac"
                continue
            end
            set -l exp_opt_name (string join '_' "EXA" $__FISH_EXA_EXPANDED_OPT_NAME[$i] "OPTIONS")
            if string match --quiet 'll*' "$name"
                alias --save "$name" "exa_git \$$exp_opt_name"
            else
                alias --save "$name" "exa \$EXA_STANDARD_OPTIONS \$$exp_opt_name \$$opt_name"
            end
            set -a __FISH_EXA_ALIASES "$name"

            if not contains $exp_opt_name $__FISH_EXA_OPT_NAMES
                set -a __FISH_EXA_OPT_NAMES $exp_opt_name
            end
        end
    end
end

function __fish_exa_update --on-event fish-exa_update
    __fish_exa_uninstall
    __fish_exa_install
end

function __fish_exa_uninstall --on-event fish-exa_uninstall
    set --erase EXA_STANDARD_OPTIONS

    for a in $__FISH_EXA_ALIASES
        functions --erase $a
        funcsave $a
    end

    for opt in $__FISH_EXA_OPT_NAMES
        set --erase $opt
    end

    set --erase __FISH_EXA_BASE_ALIASES
    set --erase __FISH_EXA_ALIASES
    set --erase __FISH_EXA_EXPANDED
    set --erase __FISH_EXA_EXPANDED_OPT_NAME
    set --erase __FISH_EXA_OPT_NAMES
    set --erase __FISH_EXA_SORT_OPTIONS
end
