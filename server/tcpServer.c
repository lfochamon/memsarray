#include "tcpServer.h"

int createSocket(){
	int socketfd;
	int yes = 1;
	struct sockaddr_in serverAddress;

	// Try to create a new socket
	socketfd = socket(AF_INET, SOCK_STREAM, 0);
	if (socketfd < 0){
		perror("Error opening socket\n");
		exit(EXIT_FAILURE);
	}

	// Mount address struct: listen on internet, on any address, and on [portnumber]
	memset((char *) &serverAddress, 0, sizeof(serverAddress));
	serverAddress.sin_family = AF_INET;
	serverAddress.sin_addr.s_addr = htonl(INADDR_ANY);
	serverAddress.sin_port = htons(PORT);

	// Avoid the "Address already in use" error message
	if (setsockopt(socketfd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(int)) == -1){
			perror("Error setting socket options. Will try to go on anyway...\n");
	}

	// Bind socket to port
	if (bind(socketfd, (struct sockaddr *) &serverAddress, sizeof(serverAddress)) < 0){
		perror("Error while binding listening socket\n");
		exit(EXIT_FAILURE);
	}

	// Return the socket file descriptor
	return(socketfd);
}


int getClientSocket(){
	int serverSocket, clientSocket;
	struct sockaddr_in clientAddress;
	socklen_t clientLength;

	// Create and bind server socket
	serverSocket = createSocket();

  // Listen on port until connection from a client socket
  if (listen(serverSocket, BACKLOG) == -1) {
    perror("Error while listening on socket");
    exit(EXIT_FAILURE);
  }

  // Accept client connection and get the client's socket information
  clientLength = sizeof(clientAddress);
  clientSocket = accept(serverSocket, (struct sockaddr *) &clientAddress, &clientLength);

  if (clientSocket < 0){
    perror("Failed to bind the client socket properly\n");
    exit(EXIT_FAILURE);
  }

  // Close server socket (no need for it anymore)
  close(serverSocket);

	// Return client socket file descriptor
	return(clientSocket);
}


int receiveData(int clientSocket, char *readBuffer, int size){
	int n;

	// Read [size] bytes from client socket
  n = recv(clientSocket, readBuffer, size, 0);

  if (n < 0){
    perror("Error reading socket");
    exit(EXIT_FAILURE);
  }

	#ifdef __DEBUG__
		printf("Received %d/%d bytes.\n", n, size);
	#endif /* __DEBUG__ */

  readBuffer[n] = '\0';

	return(n);
}


int receiveall(int clientSocket, char *readBuffer, int size){
	int received = 0;
	int n;

	while(received < size) {
		n = recv(clientSocket, readBuffer + received, size - received, 0);

		if (n < 0){
			perror("Error reading socket");
			exit(EXIT_FAILURE);
		}

		received += n;

		#ifdef __DEBUG__
			printf("Received %d/%d bytes.\n", n, size);
		#endif /* __DEBUG__ */
	}

	readBuffer[received] = '\0';

	return(received);
}


int sendData(int clientSocket, char *writeBuffer, int size){
	int n;

	// Send [size] bytes of [writeBuffer]
	n = send(clientSocket, writeBuffer, size, 0);
	if (n < 0){
		perror("Error writing to socket");
		exit(EXIT_FAILURE);
	}

	#ifdef __DEBUG__
		printf("Sent %d/%d bytes.\n", n, size);
	#endif /* __DEBUG__ */

	return(n);
}


int sendall(int clientSocket, char *writeBuffer, int size){
	int sent = 0;
	int n;

	while(sent < size) {
		n = send(clientSocket, writeBuffer + sent, size - sent, 0);

		if (n < 0){
			perror("Error writing to socket");
			exit(EXIT_FAILURE);
		}

		sent += n;

		#ifdef __DEBUG__
			printf("Sent %d/%d bytes.\n", n, size);
		#endif /* __DEBUG__ */
	}

	return(sent);
}
