using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BonitasRestClient.Models
{
    public class Process
    {
        public string id { get; set; }
        public string icon { get; set; }
        public string displayDescription { get; set; }
        public string deploymentDate { get; set; }
        public string description { get; set; }
        public string activationState { get; set; }
        public string name { get; set; }
        public string deployedBy { get; set; }
        public string displayName { get; set; }
        public string actorinitiatorid { get; set; }
        public string last_update_date { get; set; }
        public string configurationState { get; set; }
        public string version { get; set; }
    }
}
