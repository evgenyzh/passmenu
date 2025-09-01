#!/usr/bin/env bash

# Display help if requested
show_help() {
    cat <<EOF
passmenu - Password Store Interface with fuzzel/dotool integration

Usage: passmenu [OPTIONS]
Options:
  --type     Directly type password into focused window + press Enter
  --paste    Copy to clipboard and directly type password (no Enter)
  --print    Print clipboard content to terminal
  --help     Show this help message

Default behavior: Copy password to clipboard with visual confirmation

Features:
- Four access modes for different use cases
- Clipboard print option in selection menu
- Visual notifications and clipboard feedback
- Wayland-native clipboard handling
EOF
    exit 0
}

# Dependency check
dependencies=("pass" "fuzzel" "dotool" "notify-send" "wl-copy" "wl-paste")
for cmd in "${dependencies[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: $cmd not installed!" | fuzzel -d -p "passmenu: Dependency Error" 2>/dev/null
        exit 1
    fi
done

# Show help if requested
for arg in "$@"; do
    if [[ "$arg" == "--help" ]]; then
        show_help
    fi
done

# File handling options
shopt -s nullglob globstar

# Mode flags
typeit=0
pasteit=0
printit=0
delay_enter=0.1  # Delay before pressing Enter

# Determine mode for UI
mode="Copy"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --type) 
            typeit=1
            mode="Direct Type"
            ;;
        --paste)
            pasteit=1
            mode="Auto-Paste"
            ;;
        --print)
            printit=1
            mode="Print Clipboard"
            ;;
        *) 
            if [[ "$1" == -* ]]; then
                echo "Unknown option: $1" | fuzzel -d -p "passmenu: Error" 2>/dev/null
                exit 1
            fi
            ;;
    esac
    shift
done

# Get password list from store
prefix=${PASSWORD_STORE_DIR:-~/.password-store}
password_files=("$prefix"/**/*.gpg)
password_files=("${password_files[@]#"$prefix"/}")
password_files=("${password_files[@]%.gpg}")

# Add clipboard option to menu
menu_items=("${password_files[@]}")
menu_items+=("Use Clipboard Content")

# Show selection menu
selected=$(printf '%s\n' "${menu_items[@]}" | fuzzel -d -p "passmenu: $mode" "$@")
[[ -n $selected ]] || exit

# Check if clipboard option was selected
if [[ "$selected" == "Use Clipboard Content" ]]; then
    clipboard_content=$(wl-paste)
    if [[ -n "$clipboard_content" ]]; then
        # Mode: Direct typing for terminals (types + Enter)
        if [[ $typeit -eq 1 ]]; then
            echo "type $clipboard_content" | dotool       # Type clipboard content
            sleep $delay_enter                            # Short delay
            echo "key enter" | dotool                     # Press Enter
            notify-send -t 1500 "Clipboard Entered" "⌨ Content 👉 Enter"
        
        # Mode: Auto-paste for GUI apps (copies + types)
        elif [[ $pasteit -eq 1 ]]; then
            echo -n "$clipboard_content" | wl-copy        # Copy to clipboard
            echo "type $clipboard_content" | dotool       # Type clipboard content directly
            notify-send -t 1500 "Clipboard Pasted" "📥 Content"
        
        # Default mode: Print to terminal
        else
            echo "$clipboard_content"
            notify-send -t 1500 "Clipboard Printed" "📄 Content printed to terminal"
        fi
    else
        echo "Clipboard is empty"
        notify-send -t 3000 "Clipboard Empty" "⚠ No content to process"
    fi
    exit 0
fi

# Use selected password
password="$selected"

# Extract password (first line of file)
stored_password=$(pass show "$password" | head -n1)

# Mode: Direct typing for terminals (types + Enter)
if [[ $typeit -eq 1 ]]; then
    echo "type $stored_password" | dotool       # Type password
    sleep $delay_enter                          # Short delay
    echo "key enter" | dotool                   # Press Enter
    notify-send -t 1500 "Password Entered" "⌨ $password 👉 Enter"

# Mode: Auto-paste for GUI apps (copies + types)
elif [[ $pasteit -eq 1 ]]; then
    echo -n "$stored_password" | wl-copy        # Copy to clipboard
    echo "type $stored_password" | dotool       # Type password directly
    notify-send -t 1500 "Password Pasted" "📥 $password"

# Mode: Print clipboard content
elif [[ $printit -eq 1 ]]; then
    clipboard_content=$(wl-paste)
    if [[ -n "$clipboard_content" ]]; then
        echo "$clipboard_content"
        notify-send -t 1500 "Clipboard Printed" "📄 Content printed to terminal"
    else
        echo "Clipboard is empty"
        notify-send -t 3000 "Clipboard Empty" "⚠ No content to print"
    fi

# Default mode: Clipboard copy
else
    echo -n "$stored_password" | wl-copy        # Primary copy
    
    # Visual confirmation in clipboard
    if [[ $(wl-paste) == "$stored_password" ]]; then
        # Flash ✓ in clipboard
        echo -n "✓ $password" | wl-copy
        sleep 0.5
        echo -n "$stored_password" | wl-copy
        notify-send -t 1500 "Password Copied" "📋 $password"
    else
        notify-send -t 3000 "Copy Failed" "⚠ $password not in clipboard"
    fi
fi
