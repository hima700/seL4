```mermaid 
graph TB
    subgraph "CLIENT PD"
        C[CLIENT<br/>Priority: 99<br/>VSpace: 0x20000000]
        C_EP[Endpoint Cap<br/>badge=1]
        C_NF[Notification Cap]
        C_MEM[Memory Cap<br/>RW 4KB]
        
        C --> C_EP
        C --> C_NF
        C --> C_MEM
    end
    
    subgraph "SERVER PD"
        S[SERVER<br/>Priority: 100<br/>VSpace: 0x20000000]
        S_EP[Endpoint Cap<br/>passive]
        S_REPLY[Reply Cap]
        S_NF[Notification Cap]
        S_MEM[Memory Cap<br/>RW 4KB]
        
        S --> S_REPLY
        S --> S_NF
        S_EP --> S
    end
    
    subgraph "LOGGER PD"
        L[LOGGER<br/>Priority: 98<br/>Isolated VSpace]
        L_NF1[Notification Cap<br/>from CLIENT]
        L_NF2[Notification Cap<br/>from SERVER]
        
        L_NF1 --> L
        L_NF2 --> L
    end
    
    subgraph "seL4 Kernel Objects"
        EP_OBJ((Endpoint<br/>Object))
        NF_OBJ1((Notification<br/>Object 1))
        NF_OBJ2((Notification<br/>Object 2))
        SM[Shared Memory<br/>4KB Physical Region]
    end
    
    subgraph "seL4 Microkernel"
        K[Kernel Services<br/>IPC, Memory Management, Scheduling]
    end
    
    %% Endpoint connections through kernel object
    C_EP --> EP_OBJ
    EP_OBJ --> S_EP
    
    %% Reply capability
    S_REPLY --> C
    
    %% Notification connections through kernel objects
    C_NF --> NF_OBJ1
    NF_OBJ1 --> L_NF1
    
    S_NF --> NF_OBJ2
    NF_OBJ2 --> L_NF2
    
    %% Memory connections
    C_MEM --> SM
    S_MEM --> SM
    
    %% Kernel enforcement
    K -.enforces.-> C
    K -.enforces.-> S
    K -.enforces.-> L
    K -.manages.-> EP_OBJ
    K -.manages.-> NF_OBJ1
    K -.manages.-> NF_OBJ2
    K -.manages.-> SM
    
    style EP_OBJ fill:#ccffcc,stroke:#333,stroke-width:3px,color:#000
    style NF_OBJ1 fill:#ccccff,stroke:#333,stroke-width:3px,color:#000
    style NF_OBJ2 fill:#ccccff,stroke:#333,stroke-width:3px,color:#000
    style SM fill:#ffffcc,stroke:#333,stroke-width:3px,color:#000
