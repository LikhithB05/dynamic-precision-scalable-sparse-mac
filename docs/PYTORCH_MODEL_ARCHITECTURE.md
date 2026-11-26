# Original PyTorch model

| Stage | Shape or configuration |
|---|---|
| MNIST training sample | One grayscale 28×28 image, one digit label |
| torchvision transform | ToTensor converts image values to floating point in [0,1] |
| Flatten | x.view(-1,784), preserving tensor order |
| fc1 | nn.Linear(784,128), with bias |
| relu | nn.ReLU applied to the 128 hidden preactivations |
| fc2 | nn.Linear(128,10), with bias |
| Return | Ten class logits and the pre-ReLU fc1 tensor |

Adam uses learning rate 0.001 and cross-entropy on logits. The training loader shuffles with batch size 64 and runs for two epochs. The original script logs the sum of batch losses per epoch. It uses training data only and records neither held-out accuracy nor a saved model. The archived environment metadata records Python 3.14.7, torch 2.13.0, torchvision 0.28.0 and NumPy 2.5.2. The generator imports torch and torchvision directly. [Original source](../software/pytorch/mnist_dnn_mem_generator.py)
