import torch
import torch.nn as nn
import torch.optim as optim
import torchvision
import torchvision.transforms as transforms

############################################################
# PROJECT HEADER
############################################################

print("="*70)
print("ADAPTIVE PRECISION MAC - DNN WORKLOAD GENERATOR")
print("="*70)

############################################################
# LOAD MNIST DATASET
############################################################

transform = transforms.ToTensor()

trainset = torchvision.datasets.MNIST(
    root='./data',
    train=True,
    download=True,
    transform=transform
)

trainloader = torch.utils.data.DataLoader(
    trainset,
    batch_size=64,
    shuffle=True
)

print("\nMNIST Dataset Loaded Successfully")

############################################################
# DEFINE DNN
############################################################

class SimpleDNN(nn.Module):

    def __init__(self):
        super().__init__()

        self.fc1 = nn.Linear(784,128)
        self.relu = nn.ReLU()
        self.fc2 = nn.Linear(128,10)

    def forward(self,x):

        x = x.view(-1,784)

        h1 = self.fc1(x)

        x = self.relu(h1)

        x = self.fc2(x)

        return x,h1

############################################################
# CREATE MODEL
############################################################

model = SimpleDNN()

criterion = nn.CrossEntropyLoss()

optimizer = optim.Adam(
    model.parameters(),
    lr=0.001
)

############################################################
# TRAIN MODEL
############################################################

print("\nTraining DNN...")

for epoch in range(2):

    total_loss = 0

    for images,labels in trainloader:

        optimizer.zero_grad()

        outputs,_ = model(images)

        loss = criterion(outputs,labels)

        loss.backward()

        optimizer.step()

        total_loss += loss.item()

    print(
        f"Epoch {epoch+1} Loss = {total_loss:.4f}"
    )

print("\nTraining Complete")

############################################################
# GET ONE REAL MNIST IMAGE
############################################################

image,label = trainset[0]

image_flat = image.view(784)

print("\nSelected Image Label =",label)

############################################################
# EXTRACT FIRST NEURON WEIGHTS
############################################################

weights = model.fc1.weight.data[0]

############################################################
# GENERATE ACTIVATIONS
############################################################

image_input = image.view(1,784)

_,hidden_activations = model(image_input)

hidden_activations = hidden_activations.view(-1)

############################################################
# GENERATE WORKLOAD
############################################################

print("\nGenerating Adaptive Precision Workload...")

weights_int = []
activations_int = []

mode8_count = 0
mode16_count = 0
mode32_count = 0

for i in range(784):

    ########################################################
    # 8-BIT REGION
    ########################################################

    if i < 250:

        w = int(weights[i].item() * 50)
        a = int(image_flat[i].item() * 50)

        mode8_count += 1

    ########################################################
    # 16-BIT REGION
    ########################################################

    elif i < 500:

        w = int(weights[i].item() * 5000)
        a = int(image_flat[i].item() * 5000)

        mode16_count += 1

    ########################################################
    # 32-BIT REGION
    ########################################################

    else:

        w = int(weights[i].item() * 100000)
        a = int(image_flat[i].item() * 100000)

        mode32_count += 1

    weights_int.append(w)
    activations_int.append(a)

############################################################
# GENERATE HEX MEM FILES
############################################################

with open("weights.mem","w") as fw:

    for value in weights_int:

        fw.write(
            "{:08X}\n".format(value & 0xFFFFFFFF)
        )

with open("activations.mem","w") as fa:

    for value in activations_int:

        fa.write(
            "{:08X}\n".format(value & 0xFFFFFFFF)
        )

############################################################
# REPORT FILE
############################################################

with open("run_report.txt","w") as report:

    report.write("ADAPTIVE PRECISION MAC\n")
    report.write("DNN WORKLOAD REPORT\n")
    report.write("\n")

    report.write(f"Label = {label}\n")
    report.write(f"Total Values = 784\n")
    report.write("\n")

    report.write(f"8-bit Region Operations  = {mode8_count}\n")
    report.write(f"16-bit Region Operations = {mode16_count}\n")
    report.write(f"32-bit Region Operations = {mode32_count}\n")

############################################################
# DISPLAY SUMMARY
############################################################

print("\n")
print("="*70)
print("WORKLOAD GENERATION COMPLETE")
print("="*70)

print("\nGenerated Files:")

print("weights.mem")
print("activations.mem")
print("run_report.txt")

print("\nMode Distribution:")

print(f"8-bit  Operations  = {mode8_count}")
print(f"16-bit Operations  = {mode16_count}")
print(f"32-bit Operations  = {mode32_count}")

print("\nTotal Operations =",len(weights_int))

print("\nFirst 10 Weight Values:")

for i in range(10):
    print(weights_int[i])

print("\nFirst 10 Activation Values:")

for i in range(10):
    print(activations_int[i])

print("\nDone.")
print("="*70)

############################################################
# GOLDEN REFERENCE MAC VERIFICATION
############################################################

print("\n")
print("="*70)
print("GOLDEN REFERENCE MAC VERIFICATION")
print("="*70)

golden_acc = 0

for i in range(len(weights_int)):
    golden_acc += weights_int[i] * activations_int[i]

print("\nFinal MAC Accumulator (Decimal):")
print(golden_acc)

print("\nFinal MAC Accumulator (Hex):")
print(hex(golden_acc & 0xFFFFFFFFFFFFFFFF))

print("\nVerification Complete.")
print("="*70)