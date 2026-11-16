# Garbage Collector Job 🗑️

### A (no whitelist) job for a FiveM server

## Supported frameworks
- ESX
- QB
- QBX

## Dependecies
- ox_lib
- ox_inventory
- ox_target

## What you need

### 1. The item
- ox_inventory syntax

```lua
['garbage_bag'] = { -- ITEM_KEY (you can change it here and you must change it in the config)
        label = 'Garbage Bag',
        weight = 1000,
        stack = true,
        close = true,
        description = 'A heavy garbage bag!',
        client = {
            image = 'garbage_bag.png', -- Without it the image path is 'ITEM_KEY.png'
            export = 'garbagecollectorjob.useGarbageBag', -- RESOURCE_NAME.EXPORT_NAME
        }
    },
```
