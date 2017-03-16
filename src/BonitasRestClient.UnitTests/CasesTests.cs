using NUnit.Framework;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Should;
using BonitasRestClient;

namespace Blazingchilli.Common.Bpm.UnitTests
{
    [TestFixture]
    public class CasesTests
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
        public void ShouldGetCases()
        {
            var cases = client.GetCases();
            cases.Count.ShouldBeGreaterThan(0);
        }
    }
}
