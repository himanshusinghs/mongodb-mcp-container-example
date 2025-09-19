# MongoDB with MCP Server - Docker/Podman Example

This repository demonstrates the correct way to run a MongoDB server with the MongoDB Model Context Protocol (MCP) server using Docker or Podman, with proper networking configuration. There is also a sample mcp.json file to demonstrate the use with VS Code and other editors

## Problem Statement

Many users encounter connectivity issues when trying to connect an MCP server to a MongoDB instance running in containers. The primary issue is **container networking** - containers need to communicate with each other through a shared network, not through localhost.

## Solution Overview

This example shows how to:

1. Create a dedicated Docker/Podman network
2. Run MongoDB server attached to that network
3. Run the MongoDB MCP server on the same network
4. Configure the connection string to use container names instead of localhost

## Prerequisites

- Docker or Podman installed on your system
- A client that supports connecting to MCP servers, VSCode or other editors
- Basic understanding of container networking

## Quick Start

### 1. Run the MongoDB Setup

```bash
chmod +x run-mongodb.sh
./run-mongodb.sh
```

This script will:

- Create a dedicated network named `mongo-8013`
- Start a MongoDB server container
- Start the MongoDB MCP server container
- Both containers will be able to communicate through the shared network
- And you will see that the MCP server is able to establish connection to your MongoDB MCP server

### 2. Configure Your Editor

Copy the `sample-mcp.json` configuration to your editor's MCP configuration file and update the paths and names as needed. Definitely remove the comments.

## Detailed Setup

### Network Configuration

The key to proper container communication is creating a shared network:

```bash
export NETWORK_NAME="mongo-8013"
podman network create $NETWORK_NAME
```

### MongoDB Server

The MongoDB server is started with these important parameters:

```bash
export MONGODB_CONTAINER_NAME="mongo8013"
export MONGODB_ACCESS_PORT=27017

podman container run \
  --detach \
  --rm \
  --name $MONGODB_CONTAINER_NAME \
  -v MONGO_DATA_8013:/data/db \
  -p27017:27017 \
  --network $NETWORK_NAME \
  docker.io/library/mongo:latest
```

**Key points:**

- `--network $NETWORK_NAME`: Attaches container to our custom network
- `--name $MONGODB_CONTAINER_NAME`: Gives the container a predictable name for connection
- `-v MONGO_DATA_8013:/data/db`: Persists data using a named volume

### MCP Server Configuration

The MongoDB MCP server connects using the container name:

```bash
export MDB_MCP_CONNECTION_STRING="mongodb://$MONGODB_CONTAINER_NAME:$MONGODB_ACCESS_PORT"

podman run \
  --name mdb-mcp-server \
  --network $NETWORK_NAME \
  --rm \
  -i \
  -e 'MDB_MCP_READ_ONLY=true' \
  -e MDB_MCP_CONNECTION_STRING \
  mongodb/mongodb-mcp-server:latest
```

**Critical networking detail:** The connection string uses `$MONGODB_CONTAINER_NAME` (container name) instead of `localhost` because containers communicate through the Docker/Podman network using container names as hostnames.

## VS Code Integration

### MCP Configuration

Create or update your MCP configuration file (usually `~/.vscode/settings.json` or similar) with the content from `sample-mcp.json`:

```json
{
  "servers": {
    "mongodb-mcp-podman": {
      "type": "stdio",
      "command": "/usr/bin/podman",
      "args": [
        "run",
        "--name",
        "mdb-mcp-server",
        "--network",
        "mongo-8013",
        "--rm",
        "-i",
        "-e",
        "'MDB_MCP_READ_ONLY=true'",
        "-e",
        "MDB_MCP_CONNECTION_STRING",
        "mongodb/mongodb-mcp-server:latest"
      ],
      "env": {
        "MDB_MCP_CONNECTION_STRING": "mongodb://mongo8013:27017"
      }
    }
  }
}
```

**Important:** Update the `command` path to match your Podman/Docker installation path. Find it using:

```bash
which podman  # or which docker
```

## Configuration Variables

| Variable                    | Description                       | Example                     |
| --------------------------- | --------------------------------- | --------------------------- |
| `NETWORK_NAME`              | Name of the Docker/Podman network | `mongo-8013`                |
| `MONGODB_CONTAINER_NAME`    | Name of the MongoDB container     | `mongo8013`                 |
| `MONGODB_ACCESS_PORT`       | Port to expose MongoDB on         | `27017`                     |
| `MDB_MCP_CONNECTION_STRING` | Connection string for MCP server  | `mongodb://mongo8013:27017` |

## Common Mistakes to Avoid

1. **Using localhost in connection string**: Containers can't reach each other via localhost or 0.0.0.0
2. **Forgetting to create a shared network**: Containers are isolated by default
3. **Incorrect container name references**: Must match exactly between containers
4. **Wrong command path in MCP config**: Use full path to podman/docker executable

## Troubleshooting

### Check if containers are running

```bash
podman ps
```

### Check network connectivity

```bash
podman network inspect mongo-8013
```

### View container logs

```bash
podman logs mongo8013
podman logs mdb-mcp-server
```

### Test MongoDB connection from within the network

```bash
podman run --rm --network mongo-8013 -it mongo:latest mongosh mongodb://mongo8013:27017
```

## Using with Docker

To use Docker instead of Podman, simply replace `podman` with `docker` in all commands:

```bash
# In run-mongodb.sh, change:
podman network create $NETWORK_NAME
# to:
docker network create $NETWORK_NAME

# And update the MCP configuration command path accordingly
```

## Environment Variables

The MCP server supports these environment variables:

- `MDB_MCP_CONNECTION_STRING`: MongoDB connection string
- `MDB_MCP_READ_ONLY`: Set to `true` to enable read-only mode (recommended)

## Security Considerations

- The example sets `MDB_MCP_READ_ONLY=true` for safety
- Consider using authentication for production MongoDB instances
- Use specific network names to avoid conflicts
- Regularly update container images for security patches
