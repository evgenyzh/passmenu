# passmenu - Wayland Password Manager Interface 🔐

**passmenu** is a lightweight Wayland-native password manager interface that integrates with the standard `pass` password store. Designed specifically for compositors like Niri, it provides optimal workflow for password management.

## Features ✨

- **Three distinct access methods**:
  - 🔡 Direct typing (with final Enter press)
  - 📋 Clipboard copying with visual verification
  - 🚀 Auto-paste functionality for GUI apps
- Wayland-native implementation
- Full compatibility with Niri WM
- Minimal dependencies
- Visual desktop notifications

## Installation ⚙️

### 1. Install essential dependencies
```bash
# Debian/Ubuntu
sudo apt install pass fuzzel wl-clipboard libnotify-bin

# Arch Linux
sudo pacman -S pass fuzzel wl-clipboard libnotify
```

### 2. Install dotool from source
```bash
# Clone dotool repository
git clone https://git.sr.ht/~geb/dotool
cd dotool

# Build and install
sudo make install
```

### 3. Configure permissions
```bash
# Add user to input group
sudo usermod -aG input $USER

# Verify group membership
groups | grep input

# Important: Log out and back in for changes to take effect
```

### 4. Install passmenu
```bash
curl -o ~/.local/bin/passmenu https://raw.githubusercontent.com/yourusername/passmenu/main/passmenu.sh
chmod +x ~/.local/bin/passmenu
```

## Niri Configuration 🔑
Add to the binds section
```toml
    Mod+Ctrl+P hotkey-overlay-title="Paste password" { spawn "sh" "-c" "passmenu.sh --paste"; }
    Mod+Alt+P hotkey-overlay-title="Copy password" { spawn "sh" "-c" "passmenu.sh"; }
    Mod+P hotkey-overlay-title="Type password" { spawn "sh" "-c" "passmenu.sh --type"; }
```

## How It Works ⚙️

### Dotool Implementation
This dotool fork uses direct `/dev/uinput` access without requiring a separate service (unlike ydotool). Key advantages:

- **Lower latency**: Input happens immediately
- **Simpler architecture**: No background daemon needed
- **Resource efficient**: Less system overhead

```mermaid
graph LR
    passmenu.sh --> dotool
    dotool --> /dev/uinput
    /dev/uinput --> Wayland_compositor
    Wayland_compositor --> Application
```

## Usage 🚀

| Mode         | Trigger        | Ideal For          | Notification             |
|--------------|---------------|--------------------|--------------------------|
| Auto-Paste   | Mod+Ctrl+P    | Browser forms      | Password Pasted 📥      |
| Copy         | Mod+Alt+P     | Universal          | Password Copied 📋      |
| Direct Type  | Mod+P         | Terminal sessions  | Password Entered ⌨     |

## Troubleshooting 🔧

### "Input permission denied"
```bash
# Verify uinput permissions
ls -l /dev/uinput | grep 'input'

# If missing group access:
sudo chown root:input /dev/uinput
sudo chmod 660 /dev/uinput
```

### Dotool testing
```bash
# Test keyboard input
echo "type hello_system" | dotool

# Test enter key
echo "key enter" | dotool
```

## Uninstall 🗑️
```bash
# Remove passmenu script
rm ~/.local/bin/passmenu

# Remove dotool
sudo rm /usr/local/bin/dotool
```

## License 📜
MIT License - See [LICENSE](https://opensource.org/licenses/MIT)

---

**Enjoy secure password management on Wayland!** 🎉  
For support and contributions, visit [GitHub repository](https://github.com/yourusername/passmenu)

---

Эта реализация точно соответствует вашему стеку (Niri + dotool-geb) и полностью соответствует текущей конфигурации горячих клавиш. Особое внимание уделено:
1. Правильной установке dotool из source
2. Настройке прав для /dev/uinput
3. Четкой документации по режимам работы
4. Отсутствию требования к ydotoold
