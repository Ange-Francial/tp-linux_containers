#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#define SHM_NAME "/shm_example"
#define SHM_SIZE 4096

int main() {
    // Création de l'objet de mémoire partagée
    int shm_fd = shm_open(SHM_NAME, O_CREAT | O_RDWR, 0666);
    if (shm_fd == -1) {
        perror("shm_open");
        return EXIT_FAILURE;
    }

    // Redimensionner l'objet de mémoire partagée
    if (ftruncate(shm_fd, SHM_SIZE) == -1) {
        perror("ftruncate");
        return EXIT_FAILURE;
    }

    // Mappage de la mémoire partagée
    char *shared_memory = mmap(0, SHM_SIZE, PROT_WRITE, MAP_SHARED, shm_fd, 0);
    if (shared_memory == MAP_FAILED) {
        perror("mmap");
        return EXIT_FAILURE;
    }

    // Écrire dans la mémoire partagée
    const char *message = "Bonjour du producteur!";
    strncpy(shared_memory, message, SHM_SIZE);

    printf("Message écrit dans la mémoire partagée : %s\n", message);

    // Détruire le mappage et fermer le descripteur de fichier
    munmap(shared_memory, SHM_SIZE);
    close(shm_fd);

    return EXIT_SUCCESS;
}
