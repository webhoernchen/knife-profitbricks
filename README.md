# knife-profitbricks
Manage the server node at profitbricks with knife solo

### Specify your account data
As Environment

 * export PROFITBRICKS_USER=user
 * export PROFITBRICKS_PASSWORD=secure

As data bag

 * Specify user and password in the data bag
 * and set the name of the data bag
  * in your config (.chef/knife.rb)

   ```
   knife[:profitbricks_data_bag] = 'account'
   ```

  * or as parameter
    * -a account
  * data bags path
    * data_bags/profitbricks

## List all the servers in all data centers

```bash
knife profitbricks server list
```

Example:

 * DC: Data center 1
   * Server: Server name 1 (2 cores; 2048 MB RAM)
     * Allocation state: (Dea|A)llocated
     * State: RUNNING/SHUTOFF
     * OS: LINUX
     * IP: 0.0.0.0 (fixed)
     * Volumes:
       * Volume name 1 (5 GB)
       * Volume name 2 (10 GB)
     * LVS: complete
   * Server: Server name 2 (2 cores; 2048 MB RAM)
     * Allocation state: (Dea|A)llocated
     * State: RUNNING/SHUTOFF
     * OS: LINUX
     * IP: 0.0.0.0 (fixed)
     * Volumes:
       * Volume name 1 (5 GB)
       * Volume name 2 (10 GB)
     * LVS: complete
 * DC: Data center 2
   * Server: Server name 3 (2 cores; 2048 MB RAM)
     * Allocation state: (Dea|A)llocated
     * State: RUNNING/SHUTOFF
     * OS: LINUX
     * IP: 0.0.0.0 (fixed)
     * Volumes:
       * Volume name 1 (5 GB)
       * Volume name 2 (10 GB)
     * LVS: complete

## Server provision (create or update)

```bash
knife profitbricks server cook -N server_node -image PROFITBRICKS_IMAGE_NAME -u SSH_USER -authorized-key ~/.ssh/id_rsa.pub
```

Add the following profitbricks config to your node:

```json
  "profitbricks": {
    "dc": "Data center name",
    // https://devops.profitbricks.com/api/soap/#create-a-data-center => locations
    "region": "de/fkb", 
    "server": {
      "name": "name_of_the_server",
      "cores": 1,
      "ram_in_gb": 1,
      "fixed_ip": BOOLEAN,
      "volumes": {
        // Name of the volume and size in GB; Root is the boot volume
        "root": 10, 
        "volume_name_2": 10
      }
    }
  }
```

 * node
  * the profitbricks config will be used for create or update the server
  * the name of the node will be used to provision the server
 * image
  * can be a string (/^Ubuntu-14.04-LTS-server-2014-03-02/)
  * or a regex (/^Ubuntu-14.04-LTS-server-[0-9]{2,4}(-[0-9]{1,2}){1,2}/)
  * can be set in .chef/knife.rb, too!
 * ssh-user
  * can be set in .chef/knife.rb, too!
 * authorized-key
  * This public key will be uploaded as authorized_keys to the ssh-user
  * Default is the first match of ~/.ssh/*.pub
  * can be set in .chef/knife.rb, too!

### The following steps will be executed

 * Detect DC by name
  * or create if not exist
 * Detect the server by name (inside the DC) 
  * and updates the server by the given config
  * and the server will be started if not running
 * Create the server by the given config if not exist
  * Set a password for root and ssh-user
  * Upload the public key as authorized_keys to the ssh-user
 * Server provisoning by knife solo
  * with the given ssh-user
  * and for the given node
 * Add the ssh-key of the server to known hosts (local) if the server is new

## Get the ip of a server

```bash
knife profitbricks server get ip -N server_node
```

Returns the ip address of the server for the profitbricks config in the node!

Example:

```
Establish connection to ProfitBricks for "ACCOUNT"
Established ...

0.0.0.0
```

Only the IP address is written to stdout!

```bash
SERVER_IP=$(knife profitbricks server get ip -N server_node)
echo $SERVER_IP #0.0.0.0
```
