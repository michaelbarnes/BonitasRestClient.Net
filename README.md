# BonitasRestClient.Net

An abstraction of the Bonita Engine Rest API. 

## Usage
```
var client = new BpmCLient("http://localhost:8080");

var processes = client.GetProcesses();
```

## Async Methods
```
var processes = await client.GetProcessesAsync();
```
