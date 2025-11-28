# Dynamic-AGV-Task-Allocation-in-Smart-Warehouses
This project implements a Dynamic Task Allocation Framework for Automated Guided Vehicles (AGVs) inside a smart warehouse simulation using CoppeliaSim.
Tasks are assigned to AGVs in real time based on Euclidean distance, enabling adaptive scheduling and efficient navigation compared to static or zone-based allocation.

The entire warehouse simulation — including AGVs, racks, docking stations, and task-generation points is contained in a CoppeliaSim .ttt scene.

## ✨ Key Features
### 🤖 Multi-AGV Warehouse Simulation
- Multiple AGVs operating in a realistic warehouse environment.
- Includes navigation paths, pickup/drop-off points, racks, and docking areas.
- Each AGV uses child scripts for movement, sensing, and task execution.

### 🧠 Dynamic Euclidean Distance–Based Task Allocation
- Continuously monitors AGV positions and available tasks.
- Computes Euclidean distances between AGVs and task locations.
- Assigns each task to the nearest available AGV.
- Uses task-locking to prevent duplicate assignments.
- Supports continuous reassessment as tasks and AGV states change.

### 🏗️ System Architecture Components
- Task Monitor – Detects new tasks that appear in the warehouse.
- AGV Tracker – Maintains AGV availability and location.
- Distance Calculator – Computes AGV-to-task distances.
- Assignment Engine – Selects optimal AGVs for task execution.
- Coordinator – Manages task transitions and ensures conflict-free operation.

## 📂 Project Structure
 ```
├── Simulation.ttt       
├── scripts/
│   ├── TaskManager.lua        
│   ├── AGV_1.lua
│   ├── AGV_2.lua
│   └── AGV_3.lua
└── README.md                 
```
## ⚙️ Setup Instructions
1. Install CoppeliaSim

Download from:
https://www.coppeliarobotics.com/downloads

2. Clone the Repository
```
git clone https://github.com/allen-reji/Dynamic-AGV-Task-Allocation-in-Smart-Warehouses
cd Dynamic-AGV-Task-Allocation-in-Smart-Warehouses
```
3. Open the Warehouse Scene
  - Launch CoppeliaSim
  - File → Open Scene
  - Select Simulation.ttt
4. Running the Simulation
- Simply press ▶️ Play.
- AGVs will begin operating with built-in scripts.

## System Workflow
1️⃣ Task Generation <br>
  Tasks are preset locations within the warehouse.

2️⃣ Continuous Monitoring <br>
  The system tracks:

- AGV positions
- Task positions
- AGV idle/busy states

3️⃣ Distance Computation <br>
Euclidean distance is calculated for all AGV–task pairs:

<pre> distance = sqrt((x1 - x2)^2 + (y1 - y2)^2)</pre>

4️⃣ Dynamic Assignment <br>
The nearest available AGV is assigned to the task.

5️⃣ Navigation & Execution <br>
AGVs:
- Navigate to the pickup point
- Pick and deliver the item
- Report completion

6️⃣ Real-Time Updates <br>
As soon as a task finishes, or a new one appears, the cycle repeats.

## 📝 License
This project is licensed under the MIT License.

## Contact
Allen Reji - allenreji@gmail.com <br>
Nathania Rachael - nathaniarachael@gmail.com <br>
Nidhish Balasubramanya - nidhishbalasubramanya@gmail.com
