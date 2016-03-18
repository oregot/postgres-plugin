# postgres-plugin
PostgreSQL plugin for FUEL
This plugin provides ability to run postgreSQL high availability cluster on the controllers.

It contrains from:

 - on every controller node located postgrese instance
 - there is RA for postgres located in /usr/lib/ocf/resource.d/fuel/pgsql
 - high availability provides by pacemaker
 - there is Master - Slave - Slave mode
 - postgres cluster has only one public vIP 
 - public vIP provide access to Master node with RW mode
 - if postgres master will failed then another instance postgres with slave role will promote to master
 - this solution doesn't use load balancing with haproxy, and provide access direct to vIP
