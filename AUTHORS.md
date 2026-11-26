# Authors and Academic Project Acknowledgments

## Lead Developer & Repository Maintainer

- **Likhith B** ([LikhithB05](https://github.com/LikhithB05)) — Lead Developer, Primary Technical Contributor & Repository Maintainer  
  Verified individual engineering contributions in this repository include:
  - Hardware architecture design and development (Proposed Design I and Proposed Design II)
  - Verilog RTL implementation (`adaptive_mac_top`, `mac_sparse_ulp_precision_gated`, and shared Booth–Wallace submodules)
  - Dynamic precision-scalable architecture (`INT8`, `INT16`, `INT32`) and sparsity-aware gating logic (`be_enable` isolation and `!skip` accumulator enable)
  - Hardware optimization, functional verification, and Vivado XSim / Python golden-reference verification
  - Power, timing, and FPGA resource utilization analysis
  - PyTorch and MNIST workload generation (`mnist_dnn_mem_generator.py`), hardware–software integration, and technical documentation

## Academic Group Project Context

This work was developed as part of a final-year undergraduate Major project in the **Department of Electronics and Communication Engineering**, **JSS Academy of Technical Education, Bengaluru**, affiliated with **Visvesvaraya Technological University (VTU)** (Academic Year **2026–2027**).

### Academic Project Team
- **Likhith B** ([LikhithB05](https://github.com/LikhithB05))
- **K. S. Sindhura**
-  **Apoorva Sheshadri**
- **Ananya S**



*(Specific individual sub-roles for other team members are not fabricated or specified beyond team membership credited in academic project materials.)*

### Academic Project Guide
- **Mrs. Sunita L. Shirahatti**, Assistant Professor, Department of Electronics and Communication Engineering, JSS Academy of Technical Education, Bengaluru *(Academic guidance and supervision)*.

## Repository Note & Licensing Status
- The original RTL sources, testbenches, constraints, and frozen `.mem` workloads are preserved from the engineering deliverables; structured explanatory documentation, RTL-derived SVG diagrams, and independent verification harnesses support reproducibility.
- No open-source license file has been added to this repository at this stage (`No license grant authorized`).
