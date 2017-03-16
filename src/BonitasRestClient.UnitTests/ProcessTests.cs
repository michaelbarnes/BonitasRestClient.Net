using NUnit.Framework;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Should;
using Newtonsoft.Json.Linq;

namespace Blazingchilli.Common.Bpm.UnitTests
{
    [TestFixture]
    public class ProcessTests
    {
        public BpmClient client;
        public string processId;

        [TestFixtureSetUp]
        public void Init()
        {
            client = new BpmClient("http://10.0.0.132:8080/");
        }

        [Test]
        public void ShouldGetProcesses()
        {
            var processes = client.GetProcesses().Result;
            processes.Count.ShouldBeGreaterThan(0);
        }

        [Test]
        public void ShouldGetProcess()
        {
            var processes = client.GetProcesses().Result;
            var process = client.GetProcess(processes.Where(x => x.name == "CreateME").FirstOrDefault().id).Result;
            process.ShouldNotBeNull();
        }

        [Test]
        public void ShouldGetProcessConstraints()
        {
            var processes = client.GetProcesses().Result;
            var processConstraints = client.GetProcessConstraints(processes.Where(x => x.name == "CreateME").FirstOrDefault().id).Result;
            processConstraints.ShouldNotBeNull();
        }

        [Test]
        public void ShouldExecuteProcess()
        {
            client = new BpmClient("http://10.0.0.132:8080/", "helen.kelly", "bpm");
            var processes = client.GetProcesses().Result;
            client.ExecuteProcess(processes.Where(x => x.displayName == "Pool").FirstOrDefault().id, new JObject()
            {
                {"name", "Michael"},
                {"surname", "Barnes"},
                {"msisdn", "0605085161"},
                {"gender", "Male"},
                {"country", "ZA"},
            });
        }
    }
}
