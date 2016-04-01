# postgres-plugin
PostgreSQL plugin for FUEL
This plugin provides ability to run postgreSQL high availability cluster on the controllers.

Plugin based on the following points:

 - every controller node has postgreSQL instance
 - Resource Agent for postgres uses default from https://github.com/ClusterLabs/
 - high availability provides by pacemaker
 - there is Master\Slave\Slave mode
 - postgres cluster has only one public vIP 
 - public vIP provide access to Master node with RW mode
 - if postgres master will be failed then another instance postgres with
      slave role will promote to master by pacemaker
 - this solution doesn't use load balancing with haproxy, and provide access direct to vIP
 - it tested on 9.5 postgresql, but should works on 9.4 and 9.3 version


 TODO:
    - archive log require shared storage, we should provide it
	- provide support for centos ( there is only ubuntu now)
	- solution isn't tested for logevity and high availability on some cases
	- there is known issues which went from RA. If postgresql was failed, for started it 
	    you should remove recovery.conf in $HOME_PG_DIR