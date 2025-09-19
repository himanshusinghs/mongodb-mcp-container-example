# Create a common network first.
####
# This is important because the containers, by default, share a network only
# with the host machine and to enable communication between two different
# containers, we need ensure that they are in the same network.

# The network name in this example is mongo-8013, feel free to choose the name
# as you see fit.
export NETWORK_NAME="mongo-8013"

# Remove the previous network
podman network remove $NETWORK_NAME -f

# Create the network
podman network create $NETWORK_NAME

# Choose a container name for mongodb server. It's good to provide name to the
# server container, makes writing the connection string easier (see below)
export MONGODB_CONTAINER_NAME="mongo8013"

# Choose a port where the mongodb server can be accessed. This exposes
# container's internal port to the outside world, accessible through the network
# that this container is attached to
export MONGODB_ACCESS_PORT=27017

# Start mongodb server attached to the network we created above.
podman container run \
  --detach \
  --rm \
  --name $MONGODB_CONTAINER_NAME \
  -v MONGO_DATA_8013:/data/db \
  -p27017:27017 \
  --network $NETWORK_NAME \
  docker.io/library/mongo:latest
  
# Note that we construct our connection string using the container name and not
# localhost. Its because the server should be accessed from within the network
# we created and generally the container
export MDB_MCP_CONNECTION_STRING="mongodb://$MONGODB_CONTAINER_NAME:$MONGODB_ACCESS_PORT"

# Start mongodb mcp server
podman run \
  --name mdb-mcp-server \
  --network $NETWORK_NAME \
  --rm \
  -i \
  -e 'MDB_MCP_READ_ONLY=true' \
  -e MDB_MCP_CONNECTION_STRING \
  mongodb/mongodb-mcp-server:latest