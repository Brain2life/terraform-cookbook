# Run this code on EC2 instance

from xmlrpc.server import SimpleXMLRPCServer

def add_numbers(x, y):
    """Adds two numbers and returns the result."""
    return x + y

# Create an XML-RPC server
server = SimpleXMLRPCServer(("0.0.0.0", 8000))
print("Server is listening on port 8000...")

# Register the function so it can be called via RPC
server.register_function(add_numbers, "add_numbers")

# Run the server's main loop
server.serve_forever()