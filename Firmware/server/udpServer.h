#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <errno.h>

#define PORT 54321
#define BACKLOG 5


// Public functions prototypes
void socketInfo(int socketfd);
int createSocket();


// Private functions prototypes
