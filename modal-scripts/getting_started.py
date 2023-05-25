"""
modal token set --token-id {{secret('MODAL_TOKEN_ID')}} --token-secret {{secret('MODAL_TOKEN_SECRET')}}
modal token set --token-id {{envs.modal_token_id}} --token-secret {{envs.modal_token_secret}}
"""
import modal
from platform import node, platform

stub = modal.Stub("example")


@stub.function()
def square(x):
    print("This code is running on a remote worker!")
    print(f"Network: {node()}. Instance: {platform()}.")
    return x**2


@stub.local_entrypoint()
def main():
    print("the square is", square.call(42))
