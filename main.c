#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <prussdrv.h>
#include <pruss_intc_mapping.h>

#include "server/tcpServer.h"
#include "pru/pru.h"

#define MSG_SIZE (936*1024)
#define HANDSHAKE_SIZE 5
#define N_BUFFER 1

#define PRU0 0
#define PRU1 1

#define BUFFER_SIZE (2*MSG_SIZE)
#define RAM_BYTES BUFFER_SIZE
#define RAM_SIZE (RAM_BYTES / 4)
#define MAP_SIZE (RAM_BYTES + 4096UL)
#define PAGE_MASK (4096UL - 1)        /* BeagleBone Black page size: 4096 */
#define MMAP1_LOC   "/sys/class/uio/uio0/maps/map1/"


// Function to load the shared RAM memory information from sysfs
int getMemInfo(unsigned int *addr, unsigned int *size)
{
    FILE* pfile;

    // Read shared RAM address
    pfile = fopen(MMAP1_LOC "addr", "rt");
    fscanf(pfile, "%x", addr);
    fclose(pfile);

    // Read shared RAM size
    pfile = fopen(MMAP1_LOC "size", "rt");
    fscanf(pfile, "%x", size);
    fclose(pfile);

    return(0);
}


/* Handshake with client */
int client_handshake(int clientSocket)
{
    char readBuffer[HANDSHAKE_SIZE + 1];

    /* Clear receive buffer */
    memset(readBuffer, '\0', HANDSHAKE_SIZE + 1);

    /* Wait for client handshake */
    receiveData(clientSocket, readBuffer, HANDSHAKE_SIZE);
    while (strcmp(readBuffer, "") == 0)
        receiveData(clientSocket, readBuffer, HANDSHAKE_SIZE);

    /* Check handshake content */
    if (strcmp(readBuffer, "Ready") != 0)
        return(-1);

    return(0);
}


int main(int argc, char *argv[])
{
    int i;

    int fd;
    void *mem_map, *ram_addr;
    unsigned int addr, size;

    uint32_t *pru0_mem;

    int n, clientSocket;

    FILE *fp_buf;


    /* PRU code only works if executed as root */
    if (getuid() != 0) {
        fprintf(stderr, "This program needs to run as root.\n");
        exit(EXIT_FAILURE);
    }


    /***** SHARED RAM SETUP *****/
    printf("Allocating RAM buffer... ");
    fflush(stdout);

    /* Get shared RAM information */
    getMemInfo(&addr, &size);
    if (size < BUFFER_SIZE) {
        printf("error.\n");
        fprintf(stderr, "External RAM pool must be at least %d bytes.\n", BUFFER_SIZE);
        exit(EXIT_FAILURE);
    }

    /* Get access to device memory */
    if ((fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1) {
        printf("error.\n");
        perror("Failed to open memory!");
        exit(EXIT_FAILURE);
    }

    /* Map shared RAM */
    mem_map = mmap(0, RAM_BYTES, PROT_READ, MAP_SHARED, fd, addr & ~PAGE_MASK);

    /* Close file descriptor (not needed after memory mapping) */
    close(fd);

    if (mem_map == (void *) -1) {
        printf("error.\n");
        perror("Failed to map base address");
        exit(EXIT_FAILURE);
    }

    /* Memory mapping must be page aligned */
    ram_addr = mem_map + (addr & PAGE_MASK);

    printf("OK!\n");


    /***** SERVER SET UP *****/
    /* Open TCP socket */
    printf("Starting server to listen on port %d... ", PORT);
    fflush(stdout);
    clientSocket = getClientSocket();
    printf("OK!\n");

    /* Attempt to improve performance */
    n = 1;
    if (setsockopt(clientSocket, IPPROTO_TCP, TCP_NODELAY, &n, sizeof(int)) == -1)
        perror("Error setting TCP_NODELAY socket option. Will try to go on anyway...\n");

    /* Handshake with client */
    printf("Client handshake... ");
    fflush(stdout);

    if(client_handshake(clientSocket) != 0) {
        printf("error.\n");
        close(clientSocket);
        munmap(mem_map, RAM_SIZE);
        exit(EXIT_FAILURE);
    } else {
        printf("OK!\n");
    }


    /***** PRU SET UP *****/
    printf("Setting up PRUs... ");
    fflush(stdout);

    if (pru_setup() != 0) {
        printf("error.\n");
        fprintf(stderr, "Error setting up the PRU.\n");
        pru_cleanup();
        close(clientSocket);
        munmap(mem_map, RAM_SIZE);
        exit(EXIT_FAILURE);
    }

    /* Set up the PRU data RAMs */
    pru_mmap(0, &pru0_mem);
    *(pru0_mem) = addr;

    printf("OK!\n");


    /***** BEGIN MAIN PROGRAM *****/
    printf("Starting main program.\n");

    /* Start up PRU0 */
    if (pru_start(PRU0, "pru/mems_pru0.bin") != 0) {
        fprintf(stderr, "Error starting PRU0.\n");
        close(clientSocket);
        pru_cleanup();
        munmap(mem_map, RAM_SIZE);
        exit(EXIT_FAILURE);
    }

    /* Start up PRU1 */
    if (pru_start(PRU1, "pru/mems_pru1.bin") != 0) {
        fprintf(stderr, "Error starting PRU1.\n");
        close(clientSocket);
        pru_cleanup();
        munmap(mem_map, RAM_SIZE);
        exit(EXIT_FAILURE);
    }

    for (i = 0; i < N_BUFFER; i++) {
        /* Wait for PRU_EVTOUT_0 and send shared RAM data */
        prussdrv_pru_wait_event(PRU_EVTOUT_0);
        prussdrv_pru_clear_event(PRU_EVTOUT_0, PRU0_ARM_INTERRUPT);
        sendall(clientSocket, ram_addr, MSG_SIZE);

        /* Wait for PRU_EVTOUT_0 and send shared RAM data */
        prussdrv_pru_wait_event(PRU_EVTOUT_0);
        prussdrv_pru_clear_event(PRU_EVTOUT_0, PRU0_ARM_INTERRUPT);
        sendall(clientSocket, ram_addr + MSG_SIZE, MSG_SIZE);
    }


    /* PRU CLEAN UP */
    printf("Stopping PRUs.\n");
    pru_stop(PRU1);
    pru_stop(PRU0);
    pru_cleanup();

    printf("Dumpping buffer.\n");
    fp_buf = fopen("buff", "w");
    fwrite(ram_addr, sizeof(uint32_t), 2*MSG_SIZE/4, fp_buf);
    fclose(fp_buf);

    /* SERVER CLEAN UP */
    printf("Closing stream server.\n");
    close(clientSocket);

    /* SHARED RAM CLEAN UP */
    if (munmap(mem_map, RAM_SIZE) == -1) {
        perror("Failed to unmap memory");
        exit(EXIT_FAILURE);
    }

    return(EXIT_SUCCESS);
}
