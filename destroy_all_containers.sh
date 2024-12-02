#!/bin/bash

# Vérifier si des conteneurs existent
containers=$(lxc-ls)

if [ -z "$containers" ]; then
    echo "Aucun conteneur LXC trouvé."
    exit 0
fi

echo "Les conteneurs suivants existent :"
echo "$containers"
echo " "

# Demander l'autorisation pour chaque conteneur
for container in $containers; do
    # Vérifier si le conteneur est en cours d'exécution
    if lxc-info -n "$container" | grep -q "RUNNING"; then
        echo "Le conteneur '$container' est en cours d'exécution. Arrêt en cours..."
        lxc-stop -n "$container"
    fi

    # Demander confirmation pour la suppression
    read -p "Voulez-vous détruire le conteneur '$container' ? (o/N) " response
    case "$response" in
        [oO][uU][iI]|[oO])
            lxc-destroy -n "$container"
            echo "Conteneur '$container' détruit."
            ;;
        *)
            echo "Conteneur '$container' non détruit."
            ;;
    esac
done

echo "Opération terminée."
