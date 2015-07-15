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
int getMemInfo(unsigned int *addr, unsigned int *size){
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


int main(int argc, char *argv[]){
    int i;

    int fd;
    void *mem_map, *ram_addr;
    unsigned int addr, size;

    uint32_t *pru0_mem;

    FILE *fp_buf;


    /* PRU code only works if executed as root */
    if(getuid() != 0){
        fprintf(stderr, "This program needs to run as root.\n");
        exit(EXIT_FAILURE);
    }


    /***** SHARED RAM SETUP *****/
    /* Get shared RAM information */
    getMemInfo(&addr, &size);
    if(size < BUFFER_SIZE) {
        fprintf(stderr, "External RAM pool must be at least %d bytes.\n", BUFFER_SIZE);
        exit(EXIT_FAILURE);
    }

    /* Get access to device memory */
    if((fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1){
        perror("Failed to open memory!");
        exit(EXIT_FAILURE);
    }

    /* Map shared RAM */
    mem_map = mmap(0, RAM_BYTES, PROT_READ, MAP_SHARED, fd, addr & ~PAGE_MASK);

    printf("RAM buffer allocated\n");

    /* Close file descriptor (not needed after memory mapping) */
    close(fd);

    if(mem_map == (void *) -1) {
        perror("Failed to map base address");
        close(fd);
        exit(EXIT_FAILURE);
    }

    /* Memory mapping must be page aligned */
    ram_addr = mem_map + (addr & PAGE_MASK);


    /***** PRU SET UP *****/
    if(pru_setup() != 0) {
        printf("Error setting up the PRU.\n");
        pru_cleanup();
        munmap(mem_map, RAM_SIZE);
        exit(EXIT_FAILURE);
    }

    /* Set up the PRU data RAMs */
    pru_mmap(0, &pru0_mem);
    *(pru0_mem) = addr;


    /***** BEGIN MAIN PROGRAM *****/
    printf("Start PRUs\n");

    /* Start up PRU0 */
    if (pru_start(PRU0, "pru/mems_pru0.bin") != 0) {
        fprintf(stderr, "Error starting PRU0.\n");
        pru_cleanup();
        munmap(mem_map, RAM_SIZE);
        exit(EXIT_FAILURE);
    }

    /* Start up PRU1 */
    if (pru_start(PRU1, "pru/mems_pru1.bin") != 0) {
        fprintf(stderr, "Error starting PRU1.\n");
        pru_cleanup();
        munmap(mem_map, RAM_SIZE);
        exit(EXIT_FAILURE);
    }

    for(i = 0; i < N_BUFFER; i++) {
        /* Wait for PRU_EVTOUT_0 and send shared RAM data */
        prussdrv_pru_wait_event(PRU_EVTOUT_0);
        prussdrv_pru_clear_event(PRU_EVTOUT_0, PRU0_ARM_INTERRUPT);

        /* Wait for PRU_EVTOUT_0 and send shared RAM data */
        prussdrv_pru_wait_event(PRU_EVTOUT_0);
        prussdrv_pru_clear_event(PRU_EVTOUT_0, PRU0_ARM_INTERRUPT);
    }

    /* PRU CLEAN UP */
    pru_stop(PRU1);
    pru_stop(PRU0);
    pru_cleanup();

    printf("Dump buffer\n");

    fp_buf = fopen("buff", "w");
    fwrite(ram_addr, sizeof(uint32_t), 2*MSG_SIZE/4, fp_buf);
    fclose(fp_buf);

    /* SHARED RAM CLEAN UP */
    if(munmap(mem_map, RAM_SIZE) == -1) {
        perror("Failed to unmap memory");
        exit(EXIT_FAILURE);
    }
    close(fd);

    return(EXIT_SUCCESS);
}
