Bun Configuration settings

Most settings are stored in a configuration file, in YAML format. They may be listed
and set using the bun config commands. Normally, the configuration file is saved in
~/.bun_config, although this may be overridden by setting the "BUN_CONFIG" environment
variable.

Use "bun config" command to manage configuration settings. More specifically, 
"bun config init" initializes configuration settings, and "bun config ls" lists them.
All the "bun config" commands may be listed by the command "bun config help".

bun has the ability to remember "places", i.e. file paths or URLs. These may be defined
using the "bun places" commands, similarly to "bun config". Place settings are stored
with configuration, so initializing the configuration will erase all place definitions.
