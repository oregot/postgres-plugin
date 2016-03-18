# postgres-plugin
PostgreSQL plugin for FUEL
This plugin provides ability to run postgreSQL high availability cluster on the controllers.

it is based on the following points:

 - on every controller node located postgrese instance
 - Resource Agent for postgres located in /usr/lib/ocf/resource.d/fuel/pgsql
 - high availability provides by pacemaker
 - there is Master\Slave\Slave mode
 - postgres cluster has only one public vIP 
 - public vIP provide access to Master node with RW mode
 - if postgres master will be failed then another instance postgres with slave role will promote to master by pacemaker
 - this solution doesn't use load balancing with haproxy, and provide access direct to vIP
