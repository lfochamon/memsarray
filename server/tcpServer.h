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
int getClientSocket();
int receiveData(int clientSocket, char *readBuffer, int size);
int receiveall(int clientSocket, char *readBuffer, int size);
int sendData(int clientSocket, char *writeBuffer, int size);
int sendall(int clientSocket, char *writeBuffer, int size);


// Private functions prototypes
int createSocket();
