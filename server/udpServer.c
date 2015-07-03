#include "udpServer.h"


void socketInfo(int socketfd){
	int optval;
	socklen_t optlen;

	/* Data are accumulated into a single datagram that is sent when UDP_CORK is disabled. */
	printf("UDP_CORK: ");
	optlen = sizeof(int);
	getsockopt(socketfd, IPPROTO_UDP, TCP_CORK, (void *) &optval, &optlen);
	if(optval == 0)
		printf("No\n");
	else
		printf("Yes\n");

	/* MTU of current socket. Only for connected sockets. */
	printf("IP_MTU: ");
	optlen = sizeof(int);
	getsockopt(socketfd, IPPROTO_IP, IP_MTU, (void *) &optval, &optlen);
	printf("%d bytes\n", optval);

	/* Maximum socket receive buffer. The kernel doubles this value to allow space
	 * for bookkeeping overhead) when set using setsockopt and this doubled value is
	 * returned by getsockopt. The minimum (doubled) value for this option is 256.
	 * Default: /proc/sys/net/core/rmem_default
	 * Maximum: /proc/sys/net/core/rmem_max */
	printf("SO_RCVBUF: ");
	optlen = sizeof(int);
	getsockopt(socketfd, SOL_SOCKET, SO_RCVBUF, (void *) &optval, &optlen);
	printf("%d bytes\n", optval);

	/* Maximum socket send buffer. The kernel doubles this value to allow space
	 * for bookkeeping overhead) when set using setsockopt and this doubled value is
	 * returned by getsockopt. The minimum (doubled) value for this option is 2048.
	 * Default: /proc/sys/net/core/wmem_default
	 * Maximum: /proc/sys/net/core/wmem_max */
	printf("SO_SNDBUF: ");
	optlen = sizeof(int);
	getsockopt(socketfd, SOL_SOCKET, SO_SNDBUF, (void *) &optval, &optlen);
	printf("%d bytes\n", optval);

	/* Receiving timeout (struct timeval). 0 means no timeout. */
	printf("SO_RCVTIMEO: ");
	optlen = sizeof(int);
	getsockopt(socketfd, SOL_SOCKET, SO_RCVTIMEO, &optval, &optlen);
	if(optval == 0){
		printf("disabled.\n\n");
	}
	else{
		printf("%d s\n", optval);
	}

	/* Sending timeout (struct timeval). 0 means no timeout. */
	printf("SO_SNDTIMEO: ");
	optlen = sizeof(int);
	getsockopt(socketfd, SOL_SOCKET, SO_SNDTIMEO, &optval, &optlen);
	if(optval == 0){
		printf("disabled.\n\n");
	}
	else{
		printf("%d s\n", optval);
	}
}



int createSocket(){
	int socketfd;
	int yes = 1;
	struct sockaddr_in serverAddress;

	// Try to create a new socket
	socketfd = socket(AF_INET, SOCK_DGRAM, 0);
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
