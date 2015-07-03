import socket, sys

HOST = '192.168.7.2'  # Remote host
# HOST = '192.168.0.111'  # Remote host
# HOST = '192.168.0.2'    # Remote host
PORT = 54321            # Remote port
N_BUFFER = 50
MSG_SIZE = 999*1024


def substr_iter(data, length):
    for i in range(0, len(data), length):
            yield int(i/length), data[i:i+length]


# Open TCP socket
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.settimeout(5)

# Connect to server
sock.connect((HOST, PORT))

# Handshake with server
sock.send(b"Ready")

integrity = 0
grand_total = 0
for i in range(0, 2*N_BUFFER):
    full = []
    total = 0
    while total < MSG_SIZE:
        try:
            data = sock.recv(int(MSG_SIZE/4))
            full.append(data)
            total = total + len(data)
        except socket.timeout:
            print("The socket timed out during buffer", i)
            sock.close()
            sys.exit(-1)

    full = b"".join(full)
    grand_total = grand_total + total

    if all(idx % 24 == int.from_bytes(c, 'little') for idx, c in substr_iter(full, 4)):
        integrity = integrity + 1

# Close socket
sock.close()

print("The client received", grand_total/(1024*1024), "MB from the server.")

print(integrity, "messages passed the integrity check")
