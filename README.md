# knife-profitbricks-fog
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
    * -account account
  * data bags path
    * data_bags/profitbricks

## List all the servers in all data centers

```
knife profitbricks server list
```

Example:

 * DC: Data center 1
  * Server: Server name 1 (2 cores; 2048 MB RAM; IP: 0.0.0.0; state of the machine)
     * Volume: Volume name 1 (5 GB)
     * Volume: Volume name 2 (10 GB)
  * Server: Server name 2 (2 cores; 2048 MB RAM; IP: 0.0.0.0; state of the machine)
     * Volume: Volume name 1 (5 GB)
     * Volume: Volume name 2 (10 GB)
 * DC: Data center 2
  * Server: Server name 1 (2 cores; 2048 MB RAM; IP: 0.0.0.0; state of the machine)
     * Volume: Volume name 1 (5 GB)
     * Volume: Volume name 2 (10 GB)

## Server provision (create or update)

```
knife profitbricks server cook -N server_node -image PROFITBRICKS_IMAGE_NAME -x SSH_USER
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
      "volumes": {
        // Name of the volume and size in GB; Root is the boot volume
        "root": 10, 
        "application": 10,
        "mysql": 3
      }
    }
  }
```
