from modal import Stub, Image

stub = Stub("gpu-demo")


@stub.function(
    gpu="any",
    image=(
        Image.debian_slim().run_commands(
            "pip install torch --extra-index-url https://download.pytorch.org/whl/cu117"
        )
    ),
)
def print_gpu_info():
    import torch

    device_nr = torch.cuda.current_device()
    gpu_count = torch.cuda.device_count()
    device_name = torch.cuda.get_device_name(0)
    print(f"Device: {device_nr}, GPU count: {gpu_count}, Device name: {device_name}")
