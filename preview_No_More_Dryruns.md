# Implementing Web APIs for AO Processes - Goodbye Dryruns!

## Overview

> Note: This uses HyperBEAM milestone 3 functionality and is in preview only(pre-release). It is not yet recommended for applications that may lead to loss of value. There may be changes leading up to the final release and some bugs may exist yet.
> 

This guide explains how to use the `patch@1.0` AO-Core device to create RESTful-like APIs for your AO processes. This approach:

- Makes your process data accessible via HTTP endpoints
- Works from any operational AO Mainnet HyprBEAM node
- Returns cryptographically signed responses linked to individual nodes
- Eliminates the need for dry-runs in Permaweb applications

## Implementation

> To run this version of AO processes (2.0.4) first get the preview with `npm i -g [https://preview_ao.g8way.io](https://preview_ao.g8way.io/)` 
Then run `.update`  in your process to update to `2.0.4` before using state updates or it wont work correctly. You can also create a new process after this update instead if you are not migrating an existing one.
> 

The core mechanism involves sending special messages to inform the host environment to update parts of the process state cache.

### 1. Initial State Synchronization

Add this initial sync at the top of your process code:

```lua
-- Sync state on spawn
InitialSync = InitialSync or 'INCOMPLETE'
if InitialSync == 'INCOMPLETE' then
   Send({
    device = 'patch@1.0',
    cache = {
      table1 = { 
        [recordId1] = table1[recordId1] 
      },
      table2 = {
        [recordId2] = table2[recordId2]
      }
    }
  })
  InitialSync = 'COMPLETE'
end
```

### 2. State Updates During Operation

Add patch messages anywhere state changes occur. Example for an auction system:

```lua

-- Inside any handler that modifies data
Handlers.add('update-data', function(msg)
  -- Process your logic...
  table1[recordId1].field = msg.newValue
  table2[recordId2] = { 
    field1 = msg.value1, 
    field2 = msg.From 
  }
  
  -- Export the updated state
  Send({
    device = 'patch@1.0',
    cache = {
      table1 = { 
        [recordId1] = table1[recordId1] 
      },
      table2 = {
        [recordId2] = table2[recordId2]
      }
    }
  })
  
  -- Rest of handler logic...
end)
```

When you send a state update, you should see:

```
**WARN: No target specified for message. Data will be stored, but no process will receive it.**
```

This is normal and indicates your state was updated successfully. The reason for this is because the state updates that are sent to do not have a `Target` field in the message, so this response is the expected behavior and can be ignored.

## Accessing Your API

Your process data is now accessible via any HyperBEAM node:

- Get latest state: `https://router-1.forward.computer/YOUR_PROCESS_ID~process@1.0/now/cache`
- Get pre-computed state: `https://router-1.forward.computer/YOUR_PROCESS_ID~process@1.0/compute/cache`

## Sample Response Format

When accessing your data via the HTTP endpoints, the response will look like this:

```
--_XyZ123AbCdEfGhIjKlMnOpQrStUvWxYz456789
ao-types: field1="string", field2="integer", field3="integer"
recordId: record123
content-disposition: form-data;name="table1/1"
field1: value1
field2: 1000000
field3: 42
owner: wallet123
metadata: metadata456
--_XyZ123AbCdEfGhIjKlMnOpQrStUvWxYz456789
ao-types: field1="string", field2="integer", field3="integer"
recordId: record456
content-disposition: form-data;name="table1/2"
field1: value2
field2: 5000000
field3: 7
owner: wallet789
metadata: metadata123
--_XyZ123AbCdEfGhIjKlMnOpQrStUvWxYz456789
ao-types: amount="integer", timestamp="integer"
recordId: record123
content-disposition: form-data;name="table2/1"
amount: 50000000
timestamp: 1745944965943
user: wallet456
reference: record123
--_XyZ123AbCdEfGhIjKlMnOpQrStUvWxYz456789--

```

Responses will include a boundary hash (e.g., `--_XyZ123AbCdEfGhIjKlMnOpQrStUvWxYz456789` in the above example) that acts as a form-data separator, with each record containing:

- Type definitions (`ao-types`)
- Record identifiers
- Data values
- Content disposition headers

This provides a table-like structure that applications can parse and use.

## Best Practices & Tips

- For large datasets, consider selective updates to just the altered data such as only updating a single table that was altered specifically if you have multiple large tables on a process.
- Ensure all state-changing handlers include the appropriate patch messages to keep the state current with each change made
- You can name the state something other than `cache` and address it likewise with your http requests. For example name it `tables` then request data from it with `https://router-1.forward.computer/YOUR_PROCESS_ID~process@1.0/now/tables`
