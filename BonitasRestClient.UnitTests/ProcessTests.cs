using NUnit.Framework;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Should;
using Newtonsoft.Json.Linq;
using BonitasRestClient;

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
        [Ignore]
        public void ShouldGetProcesses()
        {
            var processes = client.GetProcesses();
            processes.Count.ShouldBeGreaterThan(0);
        }

        [Test]
        [Ignore]
        public void ShouldGetProcess()
        {
            var processes = client.GetProcesses();
            var process = client.GetProcess(processes.Where(x => x.name == "CreateME").FirstOrDefault().id);
            process.ShouldNotBeNull();
        }
    }
}
