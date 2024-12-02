#!/bin/bash

# Arrêter tous les conteneurs LXC en cours d'exécution
echo "Arrêt de tous les conteneurs LXC en cours d'exécution..."
for container in $(sudo lxc-ls -1); do
    sudo lxc-stop -n $container
done

# Supprimer tous les conteneurs LXC
echo "Suppression de tous les conteneurs LXC..."
for container in $(sudo lxc-ls -1); do
    sudo lxc-destroy -n $container
done

# Désinstaller LXC et ses dépendances
echo "Désinstallation de LXC et de ses dépendances..."
sudo apt-get remove --purge -y lxc
sudo apt-get autoremove -y
sudo apt-get autoclean

# Supprimer les fichiers de configuration restants
echo "Suppression des fichiers de configuration restants..."
sudo rm -rf /etc/lxc /var/lib/lxc /var/log/lxc

echo "Désinstallation complète de LXC terminée."