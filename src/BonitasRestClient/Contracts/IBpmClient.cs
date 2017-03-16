using BonitasRestClient.Models;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BonitasRestClient.Contracts
{
    public interface IBpmClient
    {
        Task<Case> GetCase(string caseId);
        Task<IList<Case>> GetCases();
        Task<Process> GetProcess(string processId);
        Task<IList<Process>> GetProcesses();
        Task ExecuteProcess(string processId, JObject payload);
        Task<Process> UpdateProcess(string processId, ProcessUpdateFields fields);
    }
}
