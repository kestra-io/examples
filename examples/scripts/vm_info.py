import modal
from platform import node, platform

stub = modal.Stub("hello")


@stub.function()
def square(x):
    print("Hello from Modal!")
    print(f"Network: {node()}. Instance: {platform()}.")
    return x**2


@stub.local_entrypoint()
def main():
    print("the square is", square.call(7))