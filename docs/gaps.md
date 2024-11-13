# Known Gaps

## Node management
- Health Checks
  - "ssh2node" is a BCM functionality that is trying to ssh into registered nodes for further management. 
    - RHCOS does not allow ssh root login by default.
    - Failing to ssh into the node will result in the node being marked as "UP (pingable)".
  - Slurm (or other predefined schedulers) are required to be installed and running.
  - Mounts - /cm/shared
  - ntpd/chronyd are required to be running.
  
