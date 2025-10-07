#!/usr/bin/env bash
set -euo pipefail

now=$(date +%d%b%Y-%H%M)

run_expect()
{
    local expect_bin=$1
    "$expect_bin" <(cat <<-EOF
      spawn passwd $USER
      expect "Enter new UNIX password:"
      send -- "$passw\r"
      expect "Retype new UNIX password:"
      send -- "$passw\r"
      expect eof
EOF
    )
    echo "Password for user $USER updated successfully"
}

setup_pass()
{
    local os=$1
    local expect_bin

    if [ -x /usr/bin/expect ]; then
        expect_bin=/usr/bin/expect
    elif [ -x /bin/expect ]; then
        expect_bin=/bin/expect
    else
        # need to install expect
        case "$os" in
          ubuntu)
            apt-get update
            apt-get install -y expect
            ;;
          centos|amzn)
            yum install -y expect
            ;;
          sles)
            zypper install -y expect
            ;;
          *)
            echo "Unsupported OS for expect install: $os" >&2
            return 1
            ;;
        esac
        # After install, reassign
        if [ -x /usr/bin/expect ]; then
            expect_bin=/usr/bin/expect
        else
            echo "expect binary not found after install" >&2
            return 1
        fi
    fi

    run_expect "$expect_bin"
}

update_conf()
{
    local sudofile="/etc/sudoers"
    local sshdfile="/etc/ssh/sshd_config"
    local sshdconfd="/etc/ssh/sshd_config.d"

    mkdir -p /home/backup
    if [ -f "$sudofile" ]; then
        cp -p "$sudofile" "/home/backup/sudoers-$now"
        if grep -q "^${USER}\b" "$sudofile"; then
            echo "$USER already present in sudoers, no change needed"
        else
            echo "$USER ALL=(ALL) NOPASSWD: ALL" >> "$sudofile"
            echo "Added $USER to sudoers"
        fi
    else
        echo "sudoers file not found at $sudofile" >&2
    fi

    # Update SSH config
    if [ -d "$sshdconfd" ]; then
        # For included config dir
        local file60="$sshdconfd/60-cloudimg-settings.conf"
        if [ -f "$file60" ]; then
            sed -i '/^PasswordAuthentication /d' "$file60"
            echo "PasswordAuthentication yes" >> "$file60"
        else
            echo "$file60 does not exist"
        fi
    else
        echo "$sshdconfd does not exist, will modify $sshdfile directly"
    fi

    if [ -f "$sshdfile" ]; then
        cp -p "$sshdfile" "/home/backup/sshd_config-$now"
        sed -i '/^ClientAliveInterval /d' "$sshdfile"
        echo "ClientAliveInterval 240" >> "$sshdfile"
        sed -i '/^PasswordAuthentication /d' "$sshdfile"
        echo "PasswordAuthentication yes" >> "$sshdfile"

        echo "Restarting SSH (service name: ssh)"
        # Use correct command
        systemctl restart ssh || service ssh restart
    else
        echo "sshd_config file not found at $sshdfile" >&2
    fi
}

########## MAIN ##########
USER="adarsha"
GROUP="dev"
passw="Adarsha2580"

if id -u "$USER" &>/dev/null; then
    echo "User $USER already exists — exiting."
    exit 0
else
    echo "User $USER not found, proceeding to create."
fi

if [ -f /etc/os-release ]; then
    osname=$(grep ^ID= /etc/os-release | cut -d= -f2 | tr -d '"')
    echo "Detected OS: $osname"
else
    echo "Cannot determine OS (no /etc/os-release)" >&2
    exit 1
fi

case "$osname" in
  ubuntu|centos|amzn|sles)
    # Remove existing, safe removal
    if id -u "$USER" &>/dev/null; then
      userdel -r "$USER" || true
    fi
    if getent group "$GROUP" >/dev/null; then
      groupdel "$GROUP" || true
    fi
    groupadd "$GROUP"
    useradd -m -d "/home/$USER" -s /bin/bash -g "$GROUP" "$USER"
    setup_pass "$osname"
    update_conf
    ;;
  *)
    echo "Unsupported OS: $osname" >&2
    exit 2
    ;;
esac

echo "Done."
exit 0
