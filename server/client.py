import socket, sys

HOST = '192.168.7.2'  # Remote host
# HOST = '192.168.0.111'  # Remote host
# HOST = '192.168.0.2'    # Remote host
PORT = 54321            # Remote port
N_BUFFER = 1
MSG_SIZE = 936*1024


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

full = []
for i in range(0, 2*N_BUFFER):
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

# Close socket
sock.close()

# print("The client received", len(full)/(1024*1024), "MB from the server.")

full = b"".join(full)

fullout = open('full.txt', 'wb')
fullout.write(full)
fullout.close()

mic1 = []
mic2 = []
for idx, word in substr_iter(full, 4):
    in_bytes = int.from_bytes(word, 'little')
    bits = bin(in_bytes).lstrip("0b")
    bits = "0"*(32-len(bits)) + bits

    mic1.extend([ bits[i] for i in range(0, 31, 2)  ])
    mic2.extend([ bits[i] for i in range(1, 31, 2)  ])

mic1 = ",".join(mic1)
mic2 = ",".join(mic2)

mic1out = open('mic1.txt', 'w')
mic1out.write(mic1)
mic1out.close()

mic2out = open('mic2.txt', 'w')
mic2out.write(mic2)
mic2out.close()
