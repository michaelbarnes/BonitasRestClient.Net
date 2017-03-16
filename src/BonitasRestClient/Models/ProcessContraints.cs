using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BonitasRestClient.Models
{
    public class ProcessConstraints
    {
        public IList<Constraint> constraints { get; set; }
        public IList<Input> inputs { get; set; }
    }

    public class Constraint
    {
        public string name { get; set; }
        public string expression { get; set; }
        public string explanation { get; set; }
        public IList<string> inputNames { get; set; }
        public string constraintType { get; set; }
    }

    public class Input
    {
        public string description { get; set; }
        public string name { get; set; }
        public bool multiple { get; set; }
        public string type { get; set; }
        public IList<Input> inputs { get; set; }
    }
}
