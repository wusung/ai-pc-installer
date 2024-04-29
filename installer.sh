#!/usr/bin/bash

curl -s https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh | bash -s --

curl -fsSL https://ollama.com/install.sh | sh


configure_systemd() {
    if ! id ollama >/dev/null 2>&1; then
        status "Creating ollama user..."
        $SUDO useradd -r -s /bin/false -U -m -d /usr/share/ollama ollama
    fi
    if getent group render >/dev/null 2>&1; then
        status "Adding ollama user to render group..."
        $SUDO usermod -a -G render ollama
    fi
    if getent group video >/dev/null 2>&1; then
        status "Adding ollama user to video group..."
        $SUDO usermod -a -G video ollama
    fi

    status "Adding current user to ollama group..."
    $SUDO usermod -a -G ollama $(whoami)

    status "Creating ollama systemd service..."
    cat <<EOF | $SUDO tee /etc/systemd/system/ollama.service >/dev/null
[Unit]
Description=Streamlit Service
After=network.target

[Service]
Type=simple
WorkingDirectory=/home/aiuser1
ExecStart=/bin/bash -c "/home/aiuser1/.miniconda3/envs/streamlit/bin/streamlit hello"
Environment="PATH=/home/aiuser1/.miniconda3/envs/streamlit/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF
    SYSTEMCTL_RUNNING="$(systemctl is-system-running || true)"
    case $SYSTEMCTL_RUNNING in
        running|degraded)
            status "Enabling and starting ollama service..."
            $SUDO systemctl daemon-reload
            $SUDO systemctl enable ollama

            start_service() { $SUDO systemctl restart ollama; }
            trap start_service EXIT
            ;;
    esac
}



