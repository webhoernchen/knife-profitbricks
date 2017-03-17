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
  * Location: de/fkb => karlsruhe
   * Traffic period: 2017.01 (In: 1.54 GB, Out: 0.35 GB)
   * Traffic period: 2016.12 (In: 1.04 GB, Out: 0.85 GB)
   * Traffic period: 2016.11 (In: 1.31 GB, Out: 0.95 GB)

  * Server: Server name 1 (2 cores - (AMD_OPTERON|INTEL_XEON); 2048 MB RAM)
   * Allocation state: (Dea|A)llocated
   * State: RUNNING/SHUTOFF
   * OS: LINUX
   * Nic 1:
    * Mac: ff:ff:ff:ff:ff:ff
    * IPs: 0.0.0.0 (reserved)
     * Traffic period: 2017.01 (In: 0.53 GB, Out: 0.15 GB)
     * Traffic period: 2016.12 (In: 0.03 GB, Out: 0.25 GB)
     * Traffic period: 2016.11 (In: 0.30 GB, Out: 0.35 GB)
   * Volumes:
    * Volume name 1 (5 GB)
    * Volume name 2 (10 GB)
   * LVS: complete
  * Server: Server name 2 (2 cores - (AMD_OPTERON|INTEL_XEON); 2048 MB RAM)
   * Allocation state: (Dea|A)llocated
   * State: RUNNING/SHUTOFF
   * OS: LINUX
   * Nic 1:
    * Mac: ff:ff:ff:ff:ff:ff
    * IPs: 0.0.0.0 (reserved), 0.0.0.1
     * Traffic period: 2017.01 (In: 1.0 GB, Out: 0.15 GB)
     * Traffic period: 2016.12 (In: 1.0 GB, Out: 0.25 GB)
     * Traffic period: 2016.11 (In: 1.0 GB, Out: 0.35 GB)
   * Volumes:
    * Volume name 1 (5 GB)
    * Volume name 2 (10 GB)
   * LVS: complete
 * DC: Data center 2
  * Server: Server name 3 (2 cores - (AMD_OPTERON|INTEL_XEON); 2048 MB RAM)
   * Allocation state: (Dea|A)llocated
   * State: RUNNING/SHUTOFF
   * OS: LINUX
   * Nic 1:
    * Mac: ff:ff:ff:ff:ff:ff
    * IPs: 0.0.0.0 (reserved)
     * Traffic period: 2017.01 (In: 0.01 GB, Out: 0.05 GB)
     * Traffic period: 2016.12 (In: 0.01 GB, Out: 0.35 GB)
     * Traffic period: 2016.11 (In: 0.01 GB, Out: 0.45 GB)
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
      "cpu": "amd",
      // or "intel"; Default is "amd"
      "ram_in_gb": 1,
      "reserve_ip": BOOLEAN,
      "volumes": {
        // Name of the volume and size in GB; Root is the boot volume
        "root": 10, 
        "volume_name_2": 10
      },
      // "image": "/regexp/"
      // "image": "IMAGE_NAME"
      "image": "REGEXP_OR_IMAGE_NAME"
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
 * reserve_dip
  * can be a boolean value
  * can only be set in node config

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
