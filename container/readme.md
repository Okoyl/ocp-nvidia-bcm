# CMD Container

```sh
podman build .
podman tag <image-id> cmdaemon
podman run -it --net=host --privileged --name cmd cmdaemoin /bin/bash
```
