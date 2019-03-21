Ensembl REST TNG - hacked about
===============================

Prototype framework for the next generation Ensembl REST server.

This prototype for the new REST server demonstrates the new method of initializing controllers. Please see the Confluence documentation for the sequence diagram and details on how controllers are found and initialized.

As well, this codebase provides one demonstration endpoint, /lookup/id, that demonstrates this initialization process.

It should be combined with the resttng_plugin_controllers repo to demonstrate loading controllers from another repo.

ADDENDUM
--------

The idea is to cannibalise REST TNG pluggable prototype REST, and turn it into a single purpose API wrapper that can be embedded into a VEP-capable docker instance and answer to Kubernetes requests