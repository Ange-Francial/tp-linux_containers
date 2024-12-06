#!/bin/bash

# Vérifier si l'utilisateur exécute le script avec des privilèges root
if [ "$(id -u)" -eq 0 ]; then
    echo "Ce script doit être exécuté avec un utilisateur non root pour configurer les conteneurs non-privilégiés."
    exit 1
fi

# Variables
USER_NAME=$(whoami)
LXC_PATH="/home/$USER_NAME/.local/share/lxc"
CONTAINER1="producteur"
CONTAINER2="consommateur"
DISTRO="alpine"
RELEASE="3.20"
ARCH="amd64"

# 1. Installation de LXC et tmux
echo "Installation de LXC et tmux si nécessaire..."
if ! command -v lxc-create &> /dev/null; then
    sudo apt update
    sudo apt install -y lxc lxc-templates
else
    echo "LXC est déjà installé."
fi

if ! command -v tmux &> /dev/null; then
    sudo apt install -y tmux
else
    echo "tmux est déjà installé."
fi

# 2. Configuration des permissions pour conteneurs non-privilégiés
echo "Configuration des permissions pour conteneurs non-privilégiés..."
SUBUID_LINE="$USER_NAME:100000:65536"
SUBGID_LINE="$USER_NAME:100000:65536"

# Ajouter les sous-identifiants à /etc/subuid et /etc/subgid
if ! grep -q "^$SUBUID_LINE" /etc/subuid; then
    echo "$SUBUID_LINE" | sudo tee -a /etc/subuid
fi
if ! grep -q "^$SUBGID_LINE" /etc/subgid; then
    echo "$SUBGID_LINE" | sudo tee -a /etc/subgid
fi

# 3. Créer les conteneurs non-privilégiés
echo "Création des conteneurs non-privilégiés..."

# Créer le conteneur producteur
if [ ! -d "$LXC_PATH/$CONTAINER1" ]; then
    lxc-create -n $CONTAINER1 -t download -- -d $DISTRO -r $RELEASE -a $ARCH
    echo "Conteneur '$CONTAINER1' créé avec succès."
else
    echo "Le conteneur '$CONTAINER1' existe déjà."
fi

# Créer le conteneur consommateur
if [ ! -d "$LXC_PATH/$CONTAINER2" ]; then
    lxc-create -n $CONTAINER2 -t download -- -d $DISTRO -r $RELEASE -a $ARCH
    echo "Conteneur '$CONTAINER2' créé avec succès."
else
    echo "Le conteneur '$CONTAINER2' existe déjà."
fi

# 4. Configurer chaque conteneur pour utiliser les UID/GID non-privilégiés
echo "Configuration des fichiers de chaque conteneur pour le mode non-privilégié..."

for CONTAINER in $CONTAINER1 $CONTAINER2; do
    CONFIG_FILE="$LXC_PATH/$CONTAINER/config"
    
    if ! grep -q "^lxc.idmap" "$CONFIG_FILE"; then
        echo "lxc.idmap = u 0 100000 65536" >> "$CONFIG_FILE"
        echo "lxc.idmap = g 0 100000 65536" >> "$CONFIG_FILE"
        echo "Fichier de configuration pour '$CONTAINER' mis à jour."
    fi

    # Vérifiez que /dev/shm est monté pour utiliser la mémoire partagée
    if ! grep -q "^lxc.mount.entry = /dev/shm" "$CONFIG_FILE"; then
        echo "lxc.mount.entry = /dev/shm dev/shm none bind,create=dir 0 0" >> "$CONFIG_FILE"
        echo "Montage de /dev/shm pour '$CONTAINER' configuré."
    fi
done

# 5. Démarrer les conteneurs
echo "Démarrage des conteneurs..."
lxc-start -n $CONTAINER1 -d && echo "Conteneur '$CONTAINER1' démarré."
lxc-start -n $CONTAINER2 -d && echo "Conteneur '$CONTAINER2' démarré."

# 6. Ouvrir tmux et attacher chaque conteneur dans un panneau différent
echo "Ouverture de tmux pour attacher les conteneurs..."
tmux new-session -d -s containers
tmux rename-window -t containers "Containers"

# Panneau 1 pour le conteneur producteur
tmux send-keys -t containers "lxc-attach -n $CONTAINER1" C-m

# Créer un deuxième panneau pour le conteneur consommateur
tmux split-window -h -t containers
tmux send-keys -t containers:0.1 "lxc-attach -n $CONTAINER2" C-m

# Sélectionner le panneau de gauche pour commencer
tmux select-pane -t containers:0.0

# Attacher à la session tmux
tmux attach -t containers