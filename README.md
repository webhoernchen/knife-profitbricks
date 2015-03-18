# knife-profitbricks-fog
Manage the server node at profitbricks with knife solo

 * Specify your account data
   * As Environment
     * export PROFITBRICKS_USER=user
     * export PROFITBRICKS_PASSWORD=secure
   * As data bag
     * Specify user and password in the data bag
     * and set the name of the data bag
       * in your config (.chef/knife.rb)
         * knife[:profitbricks_data_bag] = 'account'
     * or as parameter
       * -account account
 * List all the servers in all data centers (as wiki format)

 ...knife profitbricks server list
