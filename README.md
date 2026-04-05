# Mutagen Docker Image Wrapper

This repository provides a small Docker image wrapper around [Mutagen](https://mutagen.io/).

It is intended to package the Mutagen daemon in a reusable container image, without adding application-specific sync logic.

## Upstream documentation

For Mutagen usage, commands, and concepts, refer to the official documentation:

- https://mutagen.io/documentation/introduction/getting-started
- https://mutagen.io/documentation/introduction/daemon
- https://mutagen.io/documentation/synchronization/

## What this container does

The image:

- installs `mutagen`
- includes `mutagen-agents.tar.gz`
- starts with `mutagen daemon run`
- supports runtime `PUID` / `PGID` remapping
- keeps data under `/home/mutagen`
- generates an SSH key under `/home/mutagen/.ssh` if missing
- prints the SSH public key on startup
- includes a healthcheck using `mutagen sync list`

At container startup, the entrypoint:

1. applies `PUID` / `PGID` to the `mutagen` user
2. fixes ownership of `/home/mutagen`, `.ssh`, and `.mutagen`
3. generates an SSH key if needed
4. prints the public key
5. executes the requested command

## Docker Compose example

```yaml
services:
  mutagen:
    image: ghcr.io/vex9z7/mutagen
    container_name: mutagen
    restart: unless-stopped
    environment:
      PUID: <host-uid>
      PGID: <host-gid>
    volumes:
      - mutagen-ssh:/home/mutagen/.ssh
      - mutagen-data:/home/mutagen/.mutagen
      - <local-workspace-path>:/workspace

volumes:
  mutagen-ssh:
  mutagen-data:
```

Notes:

- `mutagen-ssh` stores the generated SSH keypair
- `mutagen-data` stores Mutagen daemon state
- `/workspace` is a bind mount placeholder for any local path you want to use in sync commands
