#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>

#define SHM_NAME "/shm_example"
#define SHM_SIZE 4096

int main() {
    // Ouverture de l'objet de mémoire partagée
    int shm_fd = shm_open(SHM_NAME, O_RDONLY, 0666);
    if (shm_fd == -1) {
        perror("shm_open");
        return EXIT_FAILURE;
    }

    // Mappage de la mémoire partagée
    char *shared_memory = mmap(0, SHM_SIZE, PROT_READ, MAP_SHARED, shm_fd, 0);
    if (shared_memory == MAP_FAILED) {
        perror("mmap");
        return EXIT_FAILURE;
    }

    // Lire le message de la mémoire partagée
    printf("Message lu dans la mémoire partagée : %s\n", shared_memory);

    // Détruire le mappage et fermer le descripteur de fichier
    munmap(shared_memory, SHM_SIZE);
    close(shm_fd);

    return EXIT_SUCCESS;
}
