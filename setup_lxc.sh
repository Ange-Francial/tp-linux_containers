#!/bin/bash

# Vérifier si LXC est installé, sinon l'installer
if ! command -v lxc-create &> /dev/null
then
    echo "LXC n'est pas installé. Installation en cours..."
    sudo apt-get update
    sudo apt-get install -y lxc
fi

# Vérifier si tmux est installé, sinon l'installer
if ! command -v tmux &> /dev/null
then
    echo "tmux n'est pas installé. Installation en cours..."
    sudo apt-get update
    sudo apt-get install -y tmux
fi

# Configuration des variables
CONTAINER1="producteur"
CONTAINER2="consommateur"
IP1="10.0.3.11"
IP2="10.0.3.12"
BRIDGE="lxcbr0"

# Créer les conteneurs non privilégiés
echo "Création des conteneurs..."
lxc-create -t download -n $CONTAINER1 -- -d ubuntu -r focal -a amd64
lxc-create -t download -n $CONTAINER2 -- -d ubuntu -r focal -a amd64

# Configurer les adresses IP des conteneurs
echo "Configuration des adresses IP..."
cat <<EOF | sudo tee /var/lib/lxc/$CONTAINER1/config
lxc.net.0.type = veth
lxc.net.0.link = $BRIDGE
lxc.net.0.flags = up
lxc.net.0.ipv4.address = $IP1/24
lxc.net.0.ipv4.gateway = 10.0.3.1
EOF

cat <<EOF | sudo tee /var/lib/lxc/$CONTAINER2/config
lxc.net.0.type = veth
lxc.net.0.link = $BRIDGE
lxc.net.0.flags = up
lxc.net.0.ipv4.address = $IP2/24
lxc.net.0.ipv4.gateway = 10.0.3.1
EOF

# Démarrer les conteneurs
echo "Démarrage des conteneurs..."
lxc-start -n $CONTAINER1
lxc-start -n $CONTAINER2

# Attacher les conteneurs à des terminaux différents en utilisant tmux
echo "Attachement des conteneurs à des terminaux tmux..."
tmux new-session -d -s mysession "lxc-attach -n $CONTAINER1"
tmux split-window -h "lxc-attach -n $CONTAINER2"
tmux select-layout even-horizontal
tmux attach -t mysession

# Afficher les informations des conteneurs
echo "Informations des conteneurs:"
lxc-ls -f

echo "Configuration terminée. Les conteneurs ont été créés, configurés avec des adresses IP différentes et attachés à des terminaux tmux."