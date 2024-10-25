import xmlrpc.client

# Replace with the public IP
server_ip = "<ec2_public_ip>"  # or "localhost" for local testing

# Create a proxy to the server
proxy = xmlrpc.client.ServerProxy(f"http://{server_ip}:8000/")

def get_sum(a, b):
    # Call the remote function as if it were local
    return proxy.add_numbers(a, b)

# Test run
if __name__ == "__main__":
    result = get_sum(2, 5)
    print(f"The result is: {result}")
