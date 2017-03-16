# BonitasRestClient.Net [![Build status](https://ci.appveyor.com/api/projects/status/hp2wo6a0sqtx54ow?svg=true)]

An abstraction of the Bonita Engine Rest API. 
In the libraries current state only basic api abstraction was made for the `process` [api](http://documentation.bonitasoft.com/?page=bpm-api#toc27). RestSharp is used for rest api integration and Json.Net used for handling certain json objects.

Please feel free to contribute and make suggestions for improvements 

## Usage
```
var client = new BpmCLient("http://localhost:8080");

var processes = client.GetProcesses();

// Get required constraints and fields to execute a process
var constraints = client.GetProcessConstraints("12345");
```

The package also has async support

```
var processes = await client.GetProcessesAsync();
```

## References
* [Bonitasoft](http://www.bonitasoft.com/) 
* [Bonitasoft Api Documentation](http://documentation.bonitasoft.com/?page=_rest-api) 
* [RestSharp](http://restsharp.org/)
* [Json.Net](http://www.newtonsoft.com/json)
